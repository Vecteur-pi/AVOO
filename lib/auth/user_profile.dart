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
  });

  final String uid;
  final String role;
  final String restaurantId;
  final String name;
  final bool active;
  final String? email;
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
    final restaurantId = _readRestaurantId(direct?.data());
    if (restaurantId != null && restaurantId.isNotEmpty) {
      final member = await _tryDoc(
        db
            .collection('restaurants')
            .doc(restaurantId)
            .collection('members')
            .doc(user.uid),
        onPermissionDenied: markPermissionDenied,
      );
      if (member != null && member.exists) {
        return _fromDoc(user, member, restaurantId: restaurantId);
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
        return _fromDoc(user, restUser, restaurantId: restaurantId);
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
  }) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final role =
        _readString(data, const ['role', 'type', 'position'], fallback: 'server');
    final name = _readString(
      data,
      const ['name', 'displayName', 'display_name', 'fullName'],
      fallback: user.displayName ?? user.email ?? 'Serveur',
    );
    final activeRaw = data['active'];
    final active = activeRaw is bool
        ? activeRaw
        : activeRaw is num
            ? activeRaw != 0
            : true;
    final resolvedRestaurantId =
        restaurantId ?? _readRestaurantId(data) ?? '';
    if (resolvedRestaurantId.isEmpty) {
      throw StateError('Restaurant introuvable pour cet utilisateur.');
    }
    return UserProfile(
      uid: user.uid,
      role: role,
      restaurantId: resolvedRestaurantId,
      name: name,
      active: active,
      email: user.email,
    );
  }

  static String? _readRestaurantId(Map<String, dynamic>? data) {
    if (data == null) return null;
    return _readString(
      data,
      const ['restaurantId', 'restaurant_id', 'restaurant', 'restaurant_ref'],
      fallback: null,
    );
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
}
