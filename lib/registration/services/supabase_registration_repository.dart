import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_config.dart';
import '../models/registration_payload.dart';
import 'mock_registration_repository.dart';
import 'registration_repository.dart';
import 'supabase_storage_service.dart';

class SupabaseRegistrationRepository implements RegistrationRepository {
  SupabaseRegistrationRepository({SupabaseStorageService? storageService})
      : _storageService = storageService ?? SupabaseStorageService();

  final SupabaseStorageService _storageService;
  final MockRegistrationRepository _fallback = MockRegistrationRepository();

  @override
  Future<bool> checkEmailUnique(String email) {
    return _fallback.checkEmailUnique(email);
  }

  @override
  Future<bool> checkPhoneUnique(String phone) {
    return _fallback.checkPhoneUnique(phone);
  }

  @override
  Future<String> uploadLogo(File file) {
    return _storageService.uploadRestaurantLogo(file);
  }

  @override
  Future<void> submitRegistration(RegistrationPayload payload) {
    return _fallback.submitRegistration(payload);
  }

  @override
  Future<void> sendEmailVerification(String email) {
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
      throw RegistrationException('email_otp_failed', 'Envoi du code impossible.');
    }
  }

  Future<void> _sendPhoneOtp(String phone) async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (error) {
      throw RegistrationException('phone_otp_failed', error.message);
    } catch (_) {
      throw RegistrationException('phone_otp_failed', 'Envoi du code impossible.');
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
}
