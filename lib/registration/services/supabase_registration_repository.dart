import 'dart:io';

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
    return _fallback.sendEmailVerification(email);
  }

  @override
  Future<void> sendPhoneVerification(String phone) {
    return _fallback.sendPhoneVerification(phone);
  }

  @override
  Future<void> verifyEmailCode(String email, String code) {
    return _fallback.verifyEmailCode(email, code);
  }

  @override
  Future<void> verifyPhoneCode(String phone, String code) {
    return _fallback.verifyPhoneCode(phone, code);
  }

  @override
  Future<void> saveDraft(RegistrationPayload payload) {
    return _fallback.saveDraft(payload);
  }
}
