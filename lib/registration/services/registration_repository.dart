import 'dart:io';

import '../models/registration_payload.dart';

class RegistrationException implements Exception {
  RegistrationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

abstract class RegistrationRepository {
  Future<bool> checkEmailUnique(String email);
  Future<bool> checkPhoneUnique(String phone);
  Future<String> uploadLogo(File file);
  Future<void> submitRegistration(RegistrationPayload payload);
  Future<void> sendEmailVerification(String email);
  Future<void> sendPhoneVerification(String phone);
  Future<void> verifyEmailCode(String email, String code);
  Future<void> verifyPhoneCode(String phone, String code);
  Future<void> saveDraft(RegistrationPayload payload);
}
