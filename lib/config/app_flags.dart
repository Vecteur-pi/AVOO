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

  // Safety guard: bypass is only active in debug builds.
  static bool get bypassOtp => kDebugMode && _bypassOtpDefine;

  // Debug-only override to keep owner onboarding visible.
  static bool get forceOwnerSetup => kDebugMode && _forceOwnerSetupDefine;
}
