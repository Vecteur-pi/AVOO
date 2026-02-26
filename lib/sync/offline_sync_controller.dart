import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../menu/repository/menu_repository.dart';
import '../menu/services/menu_image_storage_service.dart';
import '../registration/services/supabase_storage_service.dart';

enum SyncBannerState { hidden, offline, syncing, synced }

class OfflineSyncController extends ChangeNotifier with WidgetsBindingObserver {
  OfflineSyncController._({
    required SharedPreferences preferences,
    FirebaseFirestore? firestore,
    MenuRepository? menuRepository,
    MenuImageStorageService? menuImageStorageService,
    SupabaseStorageService? registrationStorageService,
    http.Client? httpClient,
  }) : _preferences = preferences,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _menuRepository = menuRepository ?? MenuRepository(),
       _menuImageStorageService =
           menuImageStorageService ?? MenuImageStorageService(),
       _registrationStorageService =
           registrationStorageService ?? SupabaseStorageService(),
       _httpClient = httpClient ?? http.Client();

  static const String _menuImageQueuePrefsKey =
      'offline_sync.pending_menu_image_jobs.v1';
  static const String _registrationLogoQueuePrefsKey =
      'offline_sync.pending_registration_logo_jobs.v1';
  static const Duration _networkProbeTimeout = Duration(seconds: 3);
  static const Duration _networkProbeInterval = Duration(seconds: 6);
  static const Duration _syncedIndicatorDuration = Duration(seconds: 2);
  static const String _networkProbeUrl =
      'https://clients3.google.com/generate_204';

  final SharedPreferences _preferences;
  final FirebaseFirestore _firestore;
  final MenuRepository _menuRepository;
  final MenuImageStorageService _menuImageStorageService;
  final SupabaseStorageService _registrationStorageService;
  final http.Client _httpClient;

  final List<_PendingMenuImageJob> _pendingMenuImageJobs =
      <_PendingMenuImageJob>[];
  final List<_PendingRegistrationLogoJob> _pendingRegistrationLogoJobs =
      <_PendingRegistrationLogoJob>[];

  StreamSubscription<void>? _snapshotsInSyncSub;
  StreamSubscription<User?>? _authStateSub;
  Timer? _networkPollTimer;
  Timer? _syncedIndicatorTimer;

  bool _isOnline = true;
  bool _isProcessingMenuQueue = false;
  bool _isProcessingRegistrationQueue = false;
  bool _hasPendingFirestoreWrites = false;
  bool _showSyncedIndicator = false;

  bool get isOnline => _isOnline;
  bool get hasPendingFirestoreWrites => _hasPendingFirestoreWrites;
  bool get hasPendingMenuJobs => _pendingMenuImageJobs.isNotEmpty;
  bool get hasPendingRegistrationLogoJobs =>
      _pendingRegistrationLogoJobs.isNotEmpty;
  int get pendingMenuJobsCount => _pendingMenuImageJobs.length;
  int get pendingRegistrationLogoJobsCount =>
      _pendingRegistrationLogoJobs.length;
  int get pendingUploadJobsCount =>
      pendingMenuJobsCount + pendingRegistrationLogoJobsCount;

  bool get _registrationJobsAwaitingAuth =>
      _pendingRegistrationLogoJobs.isNotEmpty &&
      FirebaseAuth.instance.currentUser == null;

  bool get isSyncing =>
      _isOnline &&
      (_isProcessingMenuQueue ||
          _isProcessingRegistrationQueue ||
          _hasPendingFirestoreWrites ||
          _pendingMenuImageJobs.isNotEmpty ||
          _pendingRegistrationLogoJobs.isNotEmpty);

  SyncBannerState get bannerState {
    if (!_isOnline) {
      return SyncBannerState.offline;
    }
    if (isSyncing) {
      return SyncBannerState.syncing;
    }
    if (_showSyncedIndicator) {
      return SyncBannerState.synced;
    }
    return SyncBannerState.hidden;
  }

  String get bannerMessage {
    switch (bannerState) {
      case SyncBannerState.offline:
        return 'Mode hors ligne: vos actions seront synchronisées automatiquement.';
      case SyncBannerState.syncing:
        if (_registrationJobsAwaitingAuth) {
          return 'Connectez-vous pour finaliser la synchronisation des logos.';
        }
        if (pendingUploadJobsCount > 0) {
          final count = pendingUploadJobsCount;
          final suffix = count > 1 ? 's' : '';
          return 'Synchronisation en cours ($count image$suffix en attente)...';
        }
        return 'Synchronisation en cours...';
      case SyncBannerState.synced:
        return 'Synchronisé avec Firebase.';
      case SyncBannerState.hidden:
        return '';
    }
  }

  static Future<OfflineSyncController> create() async {
    final preferences = await SharedPreferences.getInstance();
    final controller = OfflineSyncController._(preferences: preferences);
    await controller._initialize();
    return controller;
  }

  Future<void> _initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _hydrateQueuesFromPreferences();

    _snapshotsInSyncSub = _firestore.snapshotsInSync().listen((_) {
      if (!_isOnline || !_hasPendingFirestoreWrites) {
        return;
      }
      _hasPendingFirestoreWrites = false;
      _showSyncedPulse();
      notifyListeners();
    });
    _authStateSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (!_isOnline) {
        return;
      }
      if (_pendingMenuImageJobs.isNotEmpty) {
        unawaited(processPendingMenuJobs());
      }
      if (_pendingRegistrationLogoJobs.isNotEmpty) {
        unawaited(processPendingRegistrationLogoJobs());
      }
    });

    unawaited(refreshNetworkStatus());
    _networkPollTimer = Timer.periodic(_networkProbeInterval, (_) {
      unawaited(refreshNetworkStatus());
    });

    if (_pendingMenuImageJobs.isNotEmpty) {
      unawaited(processPendingMenuJobs());
    }
    if (_pendingRegistrationLogoJobs.isNotEmpty) {
      unawaited(processPendingRegistrationLogoJobs());
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(refreshNetworkStatus());
    if (_isOnline && _pendingMenuImageJobs.isNotEmpty) {
      unawaited(processPendingMenuJobs());
    }
    if (_isOnline && _pendingRegistrationLogoJobs.isNotEmpty) {
      unawaited(processPendingRegistrationLogoJobs());
    }
  }

  Future<void> refreshNetworkStatus() async {
    final online = await _probeInternetConnection();
    if (_isOnline == online) {
      if (online && _pendingMenuImageJobs.isNotEmpty) {
        unawaited(processPendingMenuJobs());
      }
      if (online && _pendingRegistrationLogoJobs.isNotEmpty) {
        unawaited(processPendingRegistrationLogoJobs());
      }
      return;
    }

    _isOnline = online;
    notifyListeners();

    if (_isOnline && _pendingMenuImageJobs.isNotEmpty) {
      unawaited(processPendingMenuJobs());
    }
    if (_isOnline && _pendingRegistrationLogoJobs.isNotEmpty) {
      unawaited(processPendingRegistrationLogoJobs());
    }
  }

  void noteFirestoreWriteQueued() {
    if (_isOnline) {
      return;
    }
    _hasPendingFirestoreWrites = true;
    notifyListeners();
  }

  Future<void> enqueueMenuImageUpload({
    required String restaurantId,
    required String itemId,
    required String localImagePath,
  }) async {
    _pendingMenuImageJobs.removeWhere(
      (job) => job.restaurantId == restaurantId && job.itemId == itemId,
    );
    _pendingMenuImageJobs.add(
      _PendingMenuImageJob(
        id: _buildJobId(),
        restaurantId: restaurantId,
        itemId: itemId,
        localImagePath: localImagePath,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _persistMenuQueue();
    notifyListeners();

    if (_isOnline) {
      unawaited(processPendingMenuJobs());
    }
  }

  Future<void> enqueueRegistrationLogoUpload({
    required String restaurantId,
    required String localImagePath,
  }) async {
    try {
      await _markRestaurantLogoPending(restaurantId, pending: true);
    } catch (_) {
      // Best-effort marker; queue persistence remains the source of truth.
    }

    _pendingRegistrationLogoJobs.removeWhere(
      (job) => job.restaurantId == restaurantId,
    );
    _pendingRegistrationLogoJobs.add(
      _PendingRegistrationLogoJob(
        id: _buildJobId(),
        restaurantId: restaurantId,
        localImagePath: localImagePath,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _persistRegistrationQueue();
    notifyListeners();

    if (_isOnline) {
      unawaited(processPendingRegistrationLogoJobs());
    }
  }

  Future<void> processPendingMenuJobs() async {
    if (_isProcessingMenuQueue || !_isOnline || _pendingMenuImageJobs.isEmpty) {
      return;
    }

    _isProcessingMenuQueue = true;
    notifyListeners();

    final remaining = <_PendingMenuImageJob>[];
    var removedAny = false;

    for (var index = 0; index < _pendingMenuImageJobs.length; index++) {
      final job = _pendingMenuImageJobs[index];
      final file = File(job.localImagePath);
      if (!await file.exists()) {
        removedAny = true;
        try {
          await _menuRepository.markPendingImageUpload(
            restaurantId: job.restaurantId,
            itemId: job.itemId,
            pending: false,
          );
        } catch (_) {
          // Best-effort cleanup for stale local files.
        }
        continue;
      }

      try {
        final imageUrl = await _menuImageStorageService.uploadMenuImage(
          file,
          restaurantId: job.restaurantId,
        );
        await _menuRepository.updateItemImage(
          job.restaurantId,
          job.itemId,
          imageUrl,
        );
        _hasPendingFirestoreWrites = true;
        removedAny = true;
      } catch (_) {
        remaining.add(job);
        final stillOnline = await _probeInternetConnection();
        if (!stillOnline) {
          _isOnline = false;
          if (index + 1 < _pendingMenuImageJobs.length) {
            remaining.addAll(_pendingMenuImageJobs.skip(index + 1));
          }
          break;
        }
      }
    }

    _pendingMenuImageJobs
      ..clear()
      ..addAll(remaining);
    await _persistMenuQueue();

    _isProcessingMenuQueue = false;

    if (_isOnline &&
        removedAny &&
        _pendingMenuImageJobs.isEmpty &&
        _pendingRegistrationLogoJobs.isEmpty) {
      _showSyncedPulse();
    }
    notifyListeners();
  }

  Future<void> processPendingRegistrationLogoJobs() async {
    if (_isProcessingRegistrationQueue ||
        !_isOnline ||
        _pendingRegistrationLogoJobs.isEmpty) {
      return;
    }
    if (FirebaseAuth.instance.currentUser == null) {
      notifyListeners();
      return;
    }

    _isProcessingRegistrationQueue = true;
    notifyListeners();

    final remaining = <_PendingRegistrationLogoJob>[];
    var removedAny = false;

    for (var index = 0; index < _pendingRegistrationLogoJobs.length; index++) {
      final job = _pendingRegistrationLogoJobs[index];
      final file = File(job.localImagePath);
      if (!await file.exists()) {
        removedAny = true;
        try {
          await _markRestaurantLogoPending(job.restaurantId, pending: false);
        } catch (_) {
          // Best-effort cleanup for stale local files.
        }
        continue;
      }

      try {
        final ownerId = FirebaseAuth.instance.currentUser?.uid;
        final imageUrl = await _registrationStorageService.uploadRestaurantLogo(
          file,
          ownerId: ownerId,
        );
        await _firestore.collection('restaurants').doc(job.restaurantId).set({
          'logo_url': imageUrl,
          'logoUrl': imageUrl,
          'logo_pending_upload': false,
          'logoPendingUpload': false,
          'updated_at': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _hasPendingFirestoreWrites = true;
        removedAny = true;
      } catch (_) {
        remaining.add(job);
        final stillOnline = await _probeInternetConnection();
        if (!stillOnline) {
          _isOnline = false;
          if (index + 1 < _pendingRegistrationLogoJobs.length) {
            remaining.addAll(_pendingRegistrationLogoJobs.skip(index + 1));
          }
          break;
        }
      }
    }

    _pendingRegistrationLogoJobs
      ..clear()
      ..addAll(remaining);
    await _persistRegistrationQueue();

    _isProcessingRegistrationQueue = false;

    if (_isOnline &&
        removedAny &&
        _pendingRegistrationLogoJobs.isEmpty &&
        _pendingMenuImageJobs.isEmpty) {
      _showSyncedPulse();
    }
    notifyListeners();
  }

  Future<bool> _probeInternetConnection() async {
    try {
      final response = await _httpClient
          .get(Uri.parse(_networkProbeUrl))
          .timeout(_networkProbeTimeout);
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markRestaurantLogoPending(
    String restaurantId, {
    required bool pending,
  }) async {
    await _firestore.collection('restaurants').doc(restaurantId).set({
      'logo_pending_upload': pending,
      'logoPendingUpload': pending,
      'updated_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _hydrateQueuesFromPreferences() {
    _hydrateMenuQueue();
    _hydrateRegistrationQueue();
  }

  void _hydrateMenuQueue() {
    final raw = _preferences.getString(_menuImageQueuePrefsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      final jobs = decoded
          .whereType<Map<dynamic, dynamic>>()
          .map(_normalizeDynamicMap)
          .map(_PendingMenuImageJob.fromJson)
          .where(
            (job) =>
                job.id.isNotEmpty &&
                job.restaurantId.isNotEmpty &&
                job.itemId.isNotEmpty &&
                job.localImagePath.isNotEmpty,
          )
          .toList(growable: false);

      _pendingMenuImageJobs
        ..clear()
        ..addAll(jobs);
    } catch (_) {
      _pendingMenuImageJobs.clear();
    }
  }

  void _hydrateRegistrationQueue() {
    final raw = _preferences.getString(_registrationLogoQueuePrefsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      final jobs = decoded
          .whereType<Map<dynamic, dynamic>>()
          .map(_normalizeDynamicMap)
          .map(_PendingRegistrationLogoJob.fromJson)
          .where(
            (job) =>
                job.id.isNotEmpty &&
                job.restaurantId.isNotEmpty &&
                job.localImagePath.isNotEmpty,
          )
          .toList(growable: false);

      _pendingRegistrationLogoJobs
        ..clear()
        ..addAll(jobs);
    } catch (_) {
      _pendingRegistrationLogoJobs.clear();
    }
  }

  Map<String, dynamic> _normalizeDynamicMap(Map<dynamic, dynamic> map) {
    final normalized = <String, dynamic>{};
    for (final entry in map.entries) {
      normalized['${entry.key}'] = entry.value;
    }
    return normalized;
  }

  Future<void> _persistMenuQueue() async {
    final encoded = jsonEncode(
      _pendingMenuImageJobs.map((job) => job.toJson()).toList(growable: false),
    );
    await _preferences.setString(_menuImageQueuePrefsKey, encoded);
  }

  Future<void> _persistRegistrationQueue() async {
    final encoded = jsonEncode(
      _pendingRegistrationLogoJobs
          .map((job) => job.toJson())
          .toList(growable: false),
    );
    await _preferences.setString(_registrationLogoQueuePrefsKey, encoded);
  }

  String _buildJobId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return '$timestamp-$random';
  }

  void _showSyncedPulse() {
    _showSyncedIndicator = true;
    _syncedIndicatorTimer?.cancel();
    _syncedIndicatorTimer = Timer(_syncedIndicatorDuration, () {
      _showSyncedIndicator = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _snapshotsInSyncSub?.cancel();
    _authStateSub?.cancel();
    _networkPollTimer?.cancel();
    _syncedIndicatorTimer?.cancel();
    _httpClient.close();
    super.dispose();
  }
}

class _PendingMenuImageJob {
  const _PendingMenuImageJob({
    required this.id,
    required this.restaurantId,
    required this.itemId,
    required this.localImagePath,
    required this.createdAtMillis,
  });

  final String id;
  final String restaurantId;
  final String itemId;
  final String localImagePath;
  final int createdAtMillis;

  factory _PendingMenuImageJob.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAtMillis'];
    return _PendingMenuImageJob(
      id: json['id'] as String? ?? '',
      restaurantId: json['restaurantId'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      localImagePath: json['localImagePath'] as String? ?? '',
      createdAtMillis: rawCreatedAt is int
          ? rawCreatedAt
          : rawCreatedAt is num
          ? rawCreatedAt.toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'itemId': itemId,
      'localImagePath': localImagePath,
      'createdAtMillis': createdAtMillis,
    };
  }
}

class _PendingRegistrationLogoJob {
  const _PendingRegistrationLogoJob({
    required this.id,
    required this.restaurantId,
    required this.localImagePath,
    required this.createdAtMillis,
  });

  final String id;
  final String restaurantId;
  final String localImagePath;
  final int createdAtMillis;

  factory _PendingRegistrationLogoJob.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAtMillis'];
    return _PendingRegistrationLogoJob(
      id: json['id'] as String? ?? '',
      restaurantId: json['restaurantId'] as String? ?? '',
      localImagePath: json['localImagePath'] as String? ?? '',
      createdAtMillis: rawCreatedAt is int
          ? rawCreatedAt
          : rawCreatedAt is num
          ? rawCreatedAt.toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'localImagePath': localImagePath,
      'createdAtMillis': createdAtMillis,
    };
  }
}
