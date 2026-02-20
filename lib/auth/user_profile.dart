import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.restaurantId,
    required this.name,
    required this.active,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final String role;
  final String restaurantId;
  final String name;
  final bool active;
  final String? email;
  final String? photoUrl;
}

class UserProfileService {
  static Future<UserProfile> load(User user) async {
    final db = FirebaseFirestore.instance;
    var permissionDenied = false;
    void markPermissionDenied() => permissionDenied = true;

    final direct = await _tryDoc(
      db.collection('users').doc(user.uid),
      onPermissionDenied: markPermissionDenied,
    );
    final directData = direct?.data();
    final restaurantId = _readRestaurantId(directData);
    final directRole = _readString(
      directData ?? const <String, dynamic>{},
      const ['role', 'type', 'position'],
      fallback: '',
    );
    final directName = _readString(
      directData ?? const <String, dynamic>{},
      const ['name', 'displayName', 'display_name', 'fullName'],
      fallback: '',
    );
    if (restaurantId != null && restaurantId.isNotEmpty) {
      if (isOwnerRole(directRole) && direct != null && direct.exists) {
        return _fromDoc(
          user,
          direct,
          restaurantId: restaurantId,
          fallbackRole: directRole,
          fallbackName: directName,
        );
      }

      final member = await _tryDoc(
        db
            .collection('restaurants')
            .doc(restaurantId)
            .collection('members')
            .doc(user.uid),
        onPermissionDenied: markPermissionDenied,
      );
      if (member != null && member.exists) {
        return _fromDoc(
          user,
          member,
          restaurantId: restaurantId,
          fallbackRole: directRole,
          fallbackName: directName,
        );
      }

      final restUser = await _tryDoc(
        db
            .collection('restaurants')
            .doc(restaurantId)
            .collection('users')
            .doc(user.uid),
        onPermissionDenied: markPermissionDenied,
      );
      if (restUser != null && restUser.exists) {
        return _fromDoc(
          user,
          restUser,
          restaurantId: restaurantId,
          fallbackRole: directRole,
          fallbackName: directName,
        );
      }

      if (direct != null && direct.exists) {
        return _fromDoc(
          user,
          direct,
          restaurantId: restaurantId,
          fallbackRole: directRole,
          fallbackName: directName,
        );
      }
    }

    if (permissionDenied) {
      throw StateError(
        "Permissions insuffisantes pour lire le profil utilisateur.",
      );
    }
    throw StateError(
      "Profil introuvable. Créez /users/{uid} avec restaurant_id.",
    );
  }

  static bool isServerRole(String role) {
    final normalized = role.toLowerCase().trim();
    return normalized == 'server' ||
        normalized == 'serveur' ||
        normalized == 'waiter' ||
        normalized == 'service';
  }

  static bool isOwnerRole(String role) {
    final normalized = role.toLowerCase().trim();
    return normalized == 'owner' ||
        normalized == 'admin' ||
        normalized == 'gerant' ||
        normalized == 'gérant' ||
        normalized == 'manager' ||
        normalized == 'proprietaire' ||
        normalized == 'propriétaire';
  }

  static Future<bool> shouldUseOwnerSetup(UserProfile profile) async {
    if (isOwnerRole(profile.role)) {
      return true;
    }

    final db = FirebaseFirestore.instance;
    final rootUser = await _tryDoc(db.collection('users').doc(profile.uid));
    if (_hasOwnerRole(rootUser)) {
      return true;
    }

    final member = await _tryDoc(
      db
          .collection('restaurants')
          .doc(profile.restaurantId)
          .collection('members')
          .doc(profile.uid),
    );
    if (_hasOwnerRole(member)) {
      return true;
    }

    final restaurantUser = await _tryDoc(
      db
          .collection('restaurants')
          .doc(profile.restaurantId)
          .collection('users')
          .doc(profile.uid),
    );
    if (_hasOwnerRole(restaurantUser)) {
      return true;
    }

    final restaurant = await _tryDoc(
      db.collection('restaurants').doc(profile.restaurantId),
    );
    final data = restaurant?.data() ?? const <String, dynamic>{};
    final ownerUid = _readString(data, const [
      'owner_uid',
      'ownerUid',
      'owner_id',
      'ownerId',
      'created_by',
      'createdBy',
    ], fallback: '');
    return ownerUid.isNotEmpty && ownerUid == profile.uid;
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>?> _tryDoc(
    DocumentReference<Map<String, dynamic>> ref, {
    void Function()? onPermissionDenied,
  }) async {
    try {
      return await ref.get();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        onPermissionDenied?.call();
        return null;
      }
      rethrow;
    }
  }

  static Future<QuerySnapshot<Map<String, dynamic>>?> _tryQuery(
    Future<QuerySnapshot<Map<String, dynamic>>> future, {
    void Function()? onPermissionDenied,
  }) async {
    try {
      return await future;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        onPermissionDenied?.call();
        return null;
      }
      rethrow;
    }
  }

  static UserProfile _fromDoc(
    User user,
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String? restaurantId,
    String? fallbackRole,
    String? fallbackName,
  }) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final resolvedFallbackRole =
        fallbackRole != null && fallbackRole.trim().isNotEmpty
        ? fallbackRole.trim()
        : 'server';
    final resolvedFallbackName =
        fallbackName != null && fallbackName.trim().isNotEmpty
        ? fallbackName.trim()
        : (user.displayName ?? user.email ?? 'Serveur');
    final role = _readString(data, const [
      'role',
      'type',
      'position',
    ], fallback: resolvedFallbackRole);
    final name = _readString(data, const [
      'name',
      'displayName',
      'display_name',
      'fullName',
    ], fallback: resolvedFallbackName);
    final activeRaw = data['active'];
    final active = activeRaw is bool
        ? activeRaw
        : activeRaw is num
        ? activeRaw != 0
        : true;
    final resolvedRestaurantId = restaurantId ?? _readRestaurantId(data) ?? '';
    if (resolvedRestaurantId.isEmpty) {
      throw StateError('Restaurant introuvable pour cet utilisateur.');
    }
    final photoUrl = _readString(data, const [
      'photoUrl',
      'photo_url',
      'photo',
      'avatar',
      'picture',
    ], fallback: null);

    return UserProfile(
      uid: user.uid,
      role: role,
      restaurantId: resolvedRestaurantId,
      name: name,
      active: active,
      email: user.email,
      photoUrl: photoUrl.isEmpty ? null : photoUrl,
    );
  }

  static String? _readRestaurantId(Map<String, dynamic>? data) {
    if (data == null) return null;
    return _readString(data, const [
      'restaurantId',
      'restaurant_id',
      'restaurant',
      'restaurant_ref',
    ], fallback: null);
  }

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String? fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback ?? '';
  }

  static bool _hasOwnerRole(DocumentSnapshot<Map<String, dynamic>>? snapshot) {
    final data = snapshot?.data();
    if (data == null) {
      return false;
    }
    final role = _readString(data, const [
      'role',
      'type',
      'position',
    ], fallback: '');
    return isOwnerRole(role);
  }
}
