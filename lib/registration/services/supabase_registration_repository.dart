import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_flags.dart';
import '../../supabase/supabase_config.dart';
import '../models/registration_payload.dart';
import 'registration_debug_state.dart';
import 'mock_registration_repository.dart';
import 'registration_repository.dart';
import 'supabase_storage_service.dart';

class SupabaseRegistrationRepository implements RegistrationRepository {
  SupabaseRegistrationRepository({SupabaseStorageService? storageService})
    : _storageService = storageService ?? SupabaseStorageService();

  final SupabaseStorageService _storageService;
  final MockRegistrationRepository _fallback = MockRegistrationRepository();

  @override
  Future<bool> checkEmailUnique(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return true;
    }

    final normalized = trimmed.toLowerCase();
    final users = FirebaseFirestore.instance.collection('users');
    try {
      final byNormalized = await users
          .where('email_lower', isEqualTo: normalized)
          .limit(1)
          .get();
      if (byNormalized.docs.isNotEmpty) {
        return false;
      }

      final byRaw = await users
          .where('email', isEqualTo: trimmed)
          .limit(1)
          .get();
      if (byRaw.docs.isNotEmpty) {
        return false;
      }
    } on FirebaseException {
      // Avoid blocking registration in dev when security rules are restrictive.
      return true;
    }
    return true;
  }

  @override
  Future<bool> checkPhoneUnique(String phone) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      return true;
    }

    try {
      final byPhone = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();
      if (byPhone.docs.isNotEmpty) {
        return false;
      }
    } on FirebaseException {
      // Avoid blocking registration in dev when security rules are restrictive.
      return true;
    }
    return true;
  }

  @override
  Future<String> uploadLogo(File file) {
    return _storageService.uploadRestaurantLogo(file);
  }

  @override
  Future<void> submitRegistration(RegistrationPayload payload) async {
    RegistrationDebugState.clear();

    final owner = payload.owner;
    final restaurant = payload.restaurant;
    final auth = fb_auth.FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final email = owner.email.trim();
    final emailLower = email.toLowerCase();
    final phone = owner.phone.trim();

    late final fb_auth.User createdUser;
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: owner.password,
      );
      final user = credential.user;
      if (user == null) {
        throw RegistrationException(
          'create_user_failed',
          'Création du compte impossible.',
        );
      }
      createdUser = user;
    } on fb_auth.FirebaseAuthException catch (error) {
      throw RegistrationException(
        _mapCreateUserErrorCode(error.code),
        _mapCreateUserErrorMessage(error.code),
      );
    } catch (_) {
      throw RegistrationException(
        'create_user_failed',
        'Création du compte impossible.',
      );
    }

    final uid = createdUser.uid;
    final restaurantRef = firestore.collection('restaurants').doc();
    final restaurantId = restaurantRef.id;
    final userRef = firestore.collection('users').doc(uid);
    final memberRef = restaurantRef.collection('members').doc(uid);
    final restaurantUserRef = restaurantRef.collection('users').doc(uid);
    final now = FieldValue.serverTimestamp();

    RegistrationDebugState.lastCreatedUid = uid;
    RegistrationDebugState.lastProjectId = firestore.app.options.projectId;
    RegistrationDebugState.lastRestaurantId = restaurantId;

    try {
      await createdUser.updateDisplayName(owner.fullName);
    } catch (_) {
      // Non-blocking: profile docs remain the source of truth.
    }

    final memberData = <String, dynamic>{
      'uid': uid,
      'name': owner.fullName,
      'email': email,
      'email_lower': emailLower,
      'phone': phone,
      'role': 'owner',
      'active': true,
      'restaurant_id': restaurantId,
      'restaurantId': restaurantId,
      'created_at': now,
      'createdAt': now,
      'updated_at': now,
      'updatedAt': now,
    };

    final batch = firestore.batch();
    batch.set(restaurantRef, <String, dynamic>{
      'id': restaurantId,
      'name': restaurant.name,
      'address': restaurant.address,
      'phone': restaurant.phone,
      'tables_count': restaurant.tablesCount,
      'tablesCount': restaurant.tablesCount,
      'configure_tables_later': restaurant.configureTablesLater,
      'configureTablesLater': restaurant.configureTablesLater,
      'logo_url': restaurant.logoUrl,
      'logoUrl': restaurant.logoUrl,
      'schedule': restaurant.schedule,
      'owner_uid': uid,
      'ownerUid': uid,
      'owner_name': owner.fullName,
      'ownerName': owner.fullName,
      'owner_email': email,
      'ownerEmail': email,
      'country_city': owner.countryCity,
      'countryCity': owner.countryCity,
      'currency': owner.currency,
      'setup_completed': false,
      'setupCompleted': false,
      'setup_steps': <String, dynamic>{
        'manager_created': false,
        'tables_added': false,
        'qr_generated': false,
        'payments_enabled': false,
      },
      'setupSteps': <String, dynamic>{
        'managerCreated': false,
        'tablesAdded': false,
        'qrGenerated': false,
        'paymentsEnabled': false,
      },
      'active': true,
      'created_at': now,
      'createdAt': now,
      'updated_at': now,
      'updatedAt': now,
    });
    batch.set(userRef, <String, dynamic>{
      'uid': uid,
      'name': owner.fullName,
      'email': email,
      'email_lower': emailLower,
      'phone': phone,
      'role': 'owner',
      'active': true,
      'restaurant_id': restaurantId,
      'restaurantId': restaurantId,
      'country_city': owner.countryCity,
      'countryCity': owner.countryCity,
      'currency': owner.currency,
      'created_at': now,
      'createdAt': now,
      'updated_at': now,
      'updatedAt': now,
    });
    batch.set(memberRef, memberData);
    batch.set(restaurantUserRef, memberData);

    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      await _cleanupFailedRegistration(createdUser);
      throw RegistrationException(
        'firestore_write_failed',
        _mapFirestoreWriteError(error.code),
      );
    } catch (_) {
      await _cleanupFailedRegistration(createdUser);
      throw RegistrationException(
        'firestore_write_failed',
        'Création du profil impossible. Réessayez.',
      );
    }

    // Keep the app flow explicit: registration creates the account, then user logs in.
    try {
      await auth.signOut();
    } catch (_) {
      // Non-blocking: account and profile are already created.
    }
  }

  @override
  Future<void> sendEmailVerification(String email) {
    if (AppFlags.bypassOtp) {
      return Future.value();
    }
    if (!SupabaseConfig.isConfigured) {
      throw RegistrationException(
        'supabase_not_configured',
        'Configurez Supabase avant l\'envoi du code.',
      );
    }
    return _sendEmailOtp(email);
  }

  @override
  Future<void> sendPhoneVerification(String phone) {
    if (AppFlags.bypassOtp) {
      return Future.value();
    }
    if (!SupabaseConfig.isConfigured) {
      throw RegistrationException(
        'supabase_not_configured',
        'Configurez Supabase avant l\'envoi du code.',
      );
    }
    return _sendPhoneOtp(phone);
  }

  @override
  Future<void> verifyEmailCode(String email, String code) {
    if (AppFlags.bypassOtp) {
      return Future.value();
    }
    if (!SupabaseConfig.isConfigured) {
      throw RegistrationException(
        'supabase_not_configured',
        'Configurez Supabase avant la vérification.',
      );
    }
    return _verifyEmailOtp(email, code);
  }

  @override
  Future<void> verifyPhoneCode(String phone, String code) {
    if (AppFlags.bypassOtp) {
      return Future.value();
    }
    if (!SupabaseConfig.isConfigured) {
      throw RegistrationException(
        'supabase_not_configured',
        'Configurez Supabase avant la vérification.',
      );
    }
    return _verifyPhoneOtp(phone, code);
  }

  @override
  Future<void> saveDraft(RegistrationPayload payload) {
    return _fallback.saveDraft(payload);
  }

  Future<void> _sendEmailOtp(String email) async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
    } on AuthException catch (error) {
      throw RegistrationException('email_otp_failed', error.message);
    } catch (_) {
      throw RegistrationException(
        'email_otp_failed',
        'Envoi du code impossible.',
      );
    }
  }

  Future<void> _sendPhoneOtp(String phone) async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (error) {
      throw RegistrationException('phone_otp_failed', error.message);
    } catch (_) {
      throw RegistrationException(
        'phone_otp_failed',
        'Envoi du code impossible.',
      );
    }
  }

  Future<void> _verifyEmailOtp(String email, String code) async {
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
    } on AuthException catch (error) {
      throw RegistrationException('invalid_code', error.message);
    } catch (_) {
      throw RegistrationException('invalid_code', 'Code invalide.');
    }
  }

  Future<void> _verifyPhoneOtp(String phone, String code) async {
    try {
      await Supabase.instance.client.auth.verifyOTP(
        phone: phone,
        token: code,
        type: OtpType.sms,
      );
    } on AuthException catch (error) {
      throw RegistrationException('invalid_code', error.message);
    } catch (_) {
      throw RegistrationException('invalid_code', 'Code invalide.');
    }
  }

  Future<void> _cleanupFailedRegistration(fb_auth.User createdUser) async {
    try {
      await createdUser.delete();
    } catch (_) {
      // Ignore cleanup failures.
    }
    try {
      await fb_auth.FirebaseAuth.instance.signOut();
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  String _mapCreateUserErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'email_exists';
      case 'weak-password':
        return 'weak_password';
      case 'invalid-email':
        return 'invalid_email';
      default:
        return 'create_user_failed';
    }
  }

  String _mapCreateUserErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cet e-mail est déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop faible.';
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'operation-not-allowed':
        return 'Inscription non autorisée sur Firebase.';
      default:
        return 'Création du compte impossible.';
    }
  }

  String _mapFirestoreWriteError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Permissions Firestore insuffisantes pour créer le profil.';
      default:
        return 'Création du profil impossible. Réessayez.';
    }
  }
}
