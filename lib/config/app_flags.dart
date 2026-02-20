import 'package:flutter/foundation.dart';

class AppFlags {
  static const bool _bypassOtpDefine = bool.fromEnvironment(
    'BYPASS_OTP',
    defaultValue: false,
  );
  static const bool _forceOwnerSetupDefine = bool.fromEnvironment(
    'FORCE_OWNER_SETUP',
    defaultValue: false,
  );
  static const String _temporaryOtpBypassEmailDefine = String.fromEnvironment(
    'TEMP_OTP_BYPASS_EMAIL',
    defaultValue: '',
  );
  static const String _temporaryOtpBypassPhoneDefine = String.fromEnvironment(
    'TEMP_OTP_BYPASS_PHONE',
    defaultValue: '',
  );
  static const String _temporaryOtpBypassCodeDefine = String.fromEnvironment(
    'TEMP_OTP_BYPASS_CODE',
    defaultValue: '',
  );

  // Safety guard: bypass is only active in debug builds.
  static bool get bypassOtp => kDebugMode && _bypassOtpDefine;

  // Debug-only override to keep owner onboarding visible.
  static bool get forceOwnerSetup => kDebugMode && _forceOwnerSetupDefine;

  // Temporary escape hatch for a specific friend/tester contact.
  static String get temporaryOtpBypassEmail =>
      _temporaryOtpBypassEmailDefine.trim().toLowerCase();

  static String get temporaryOtpBypassPhone =>
      _temporaryOtpBypassPhoneDefine.replaceAll(' ', '').trim();

  static String get temporaryOtpBypassCode =>
      _temporaryOtpBypassCodeDefine.trim();

  static bool get temporaryOtpBypassConfigured {
    return temporaryOtpBypassCode.isNotEmpty &&
        (temporaryOtpBypassEmail.isNotEmpty ||
            temporaryOtpBypassPhone.isNotEmpty);
  }
}
