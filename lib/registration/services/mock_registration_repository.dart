import 'dart:async';
import 'dart:io';

import '../models/registration_payload.dart';
import 'registration_repository.dart';

class MockRegistrationRepository implements RegistrationRepository {
  static const _mockDelay = Duration(milliseconds: 650);
  static const _mockCode = '123456';

  @override
  Future<bool> checkEmailUnique(String email) async {
    await Future.delayed(_mockDelay);
    final lower = email.toLowerCase();
    if (lower.contains('used') || lower.contains('taken')) {
      return false;
    }
    return true;
  }

  @override
  Future<bool> checkPhoneUnique(String phone) async {
    await Future.delayed(_mockDelay);
    if (phone.endsWith('0000') || phone.contains('999')) {
      return false;
    }
    return true;
  }

  @override
  Future<String> uploadLogo(File file) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return 'https://cdn.avoo.app/uploads/logo_${DateTime.now().millisecondsSinceEpoch}.png';
  }

  @override
  Future<void> submitRegistration(RegistrationPayload payload) async {
    await Future.delayed(const Duration(seconds: 1));
    final email = payload.owner.email.toLowerCase();
    final phone = payload.owner.phone;
    if (email.contains('used')) {
      throw RegistrationException('email_exists', 'Cet e-mail est déjà utilisé.');
    }
    if (phone.endsWith('0000')) {
      throw RegistrationException('phone_exists', 'Ce numéro est déjà utilisé.');
    }
  }

  @override
  Future<void> sendEmailVerification(String email) async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<void> sendPhoneVerification(String phone) async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<void> verifyEmailCode(String email, String code) async {
    await Future.delayed(const Duration(milliseconds: 650));
    if (code != _mockCode) {
      throw RegistrationException('invalid_code', 'Code invalide.');
    }
  }

  @override
  Future<void> verifyPhoneCode(String phone, String code) async {
    await Future.delayed(const Duration(milliseconds: 650));
    if (code != _mockCode) {
      throw RegistrationException('invalid_code', 'Code invalide.');
    }
  }

  @override
  Future<void> saveDraft(RegistrationPayload payload) async {
    await Future.delayed(const Duration(milliseconds: 350));
  }
}
