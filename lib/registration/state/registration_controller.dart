import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_flags.dart';
import '../models/personal_info.dart';
import '../models/registration_payload.dart';
import '../models/restaurant_info.dart';
import '../models/verification_method.dart';
import '../services/registration_repository.dart';
import '../utils/registration_validators.dart';

class RegistrationController extends ChangeNotifier {
  RegistrationController({required this.repository}) {
    _bindListeners();
  }

  final RegistrationRepository repository;

  final formKeyStep1 = GlobalKey<FormState>();
  final formKeyStep2 = GlobalKey<FormState>();
  final formKeyStep3 = GlobalKey<FormState>();

  int currentStep = 0;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final countryCityController = TextEditingController();
  String currency = 'FCFA';

  final restaurantNameController = TextEditingController();
  final restaurantAddressController = TextEditingController();
  final restaurantPhoneController = TextEditingController();
  final tablesCountController = TextEditingController();
  final scheduleController = TextEditingController();

  final verificationCodeController = TextEditingController();

  bool configureTablesLater = false;
  XFile? logoFile;

  bool isCheckingUnique = false;
  bool isSendingCode = false;
  bool isVerifying = false;
  bool isSubmitting = false;

  String? emailUniqueError;
  String? phoneUniqueError;
  String? verificationError;
  String? submitError;

  bool verificationSent = false;
  VerificationMethod verificationMethod = VerificationMethod.email;

  int resendSeconds = 0;
  Timer? _resendTimer;

  void _bindListeners() {
    fullNameController.addListener(_notify);
    emailController.addListener(() {
      if (emailUniqueError != null) {
        emailUniqueError = null;
      }
      _notify();
    });
    phoneController.addListener(() {
      if (phoneUniqueError != null) {
        phoneUniqueError = null;
      }
      _notify();
    });
    passwordController.addListener(_notify);
    countryCityController.addListener(_notify);
    restaurantNameController.addListener(_notify);
    restaurantAddressController.addListener(_notify);
    restaurantPhoneController.addListener(_notify);
    tablesCountController.addListener(_notify);
    verificationCodeController.addListener(() {
      if (verificationError != null) {
        verificationError = null;
      }
      _notify();
    });
  }

  void _notify() {
    notifyListeners();
  }

  bool get canProceedStep1 {
    return RegistrationValidators.fullName(fullNameController.text) == null &&
        RegistrationValidators.email(emailController.text) == null &&
        RegistrationValidators.phone(phoneController.text) == null &&
        RegistrationValidators.password(passwordController.text) == null &&
        RegistrationValidators.countryCity(countryCityController.text) ==
            null &&
        RegistrationValidators.currency(currency) == null &&
        emailUniqueError == null &&
        phoneUniqueError == null &&
        !isCheckingUnique;
  }

  bool get canProceedStep2 {
    return RegistrationValidators.restaurantName(
              restaurantNameController.text,
            ) ==
            null &&
        RegistrationValidators.restaurantAddress(
              restaurantAddressController.text,
            ) ==
            null &&
        RegistrationValidators.restaurantPhone(
              restaurantPhoneController.text,
            ) ==
            null &&
        RegistrationValidators.tablesCount(
              tablesCountController.text,
              configureTablesLater,
            ) ==
            null;
  }

  bool get canSubmit {
    final codeIsValid =
        AppFlags.bypassOtp ||
        RegistrationValidators.verificationCode(
              verificationCodeController.text,
            ) ==
            null;
    return codeIsValid && !isVerifying && !isSubmitting;
  }

  bool get isTemporaryOtpBypassAvailableForSelectedContact {
    return _isTemporaryOtpBypassContactMatched();
  }

  bool get isOtpBypassActiveForSelectedContact {
    return AppFlags.bypassOtp ||
        isTemporaryOtpBypassAvailableForSelectedContact;
  }

  void updateCurrency(String value) {
    currency = value;
    _notify();
  }

  void toggleConfigureTablesLater(bool value) {
    configureTablesLater = value;
    if (value) {
      tablesCountController.clear();
    }
    _notify();
  }

  void setVerificationMethod(VerificationMethod method) {
    verificationMethod = method;
    verificationError = null;
    _notify();
  }

  Future<bool> submitStep1() async {
    submitError = null;
    final form = formKeyStep1.currentState;
    if (form == null || !form.validate()) {
      return false;
    }
    isCheckingUnique = true;
    emailUniqueError = null;
    phoneUniqueError = null;
    _notify();

    final emailUnique = await repository.checkEmailUnique(
      emailController.text.trim(),
    );
    final phoneUnique = await repository.checkPhoneUnique(
      RegistrationValidators.normalizePhone(phoneController.text),
    );

    if (!emailUnique) {
      emailUniqueError = 'Cet e-mail est déjà utilisé.';
    }
    if (!phoneUnique) {
      phoneUniqueError = 'Ce numéro est déjà utilisé.';
    }

    isCheckingUnique = false;
    _notify();
    return emailUnique && phoneUnique;
  }

  bool submitStep2() {
    submitError = null;
    final form = formKeyStep2.currentState;
    if (form == null) {
      return false;
    }
    return form.validate();
  }

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (result != null) {
      logoFile = result;
      _notify();
    }
  }

  void removeLogo() {
    logoFile = null;
    _notify();
  }

  Future<void> sendVerificationCode() async {
    if (isSendingCode || resendSeconds > 0) {
      return;
    }
    if (isOtpBypassActiveForSelectedContact) {
      verificationError = null;
      verificationSent = true;
      _startResendTimer();
      _notify();
      return;
    }
    isSendingCode = true;
    verificationError = null;
    _notify();

    try {
      if (verificationMethod == VerificationMethod.email) {
        await repository.sendEmailVerification(emailController.text.trim());
      } else {
        await repository.sendPhoneVerification(
          RegistrationValidators.normalizePhone(phoneController.text),
        );
      }
      verificationSent = true;
      _startResendTimer();
    } on RegistrationException catch (error) {
      verificationError = error.message;
    } catch (_) {
      verificationError = 'Impossible d\'envoyer le code.';
    } finally {
      isSendingCode = false;
      _notify();
    }
  }

  Future<bool> completeRegistration() async {
    submitError = null;
    verificationError = null;
    final form = formKeyStep3.currentState;
    if (!AppFlags.bypassOtp && (form == null || !form.validate())) {
      return false;
    }

    final shouldSkipOtpVerification =
        AppFlags.bypassOtp || _isTemporaryOtpBypassCodeValid();

    if (!shouldSkipOtpVerification) {
      isVerifying = true;
      _notify();

      try {
        if (verificationMethod == VerificationMethod.email) {
          await repository.verifyEmailCode(
            emailController.text.trim(),
            verificationCodeController.text.trim(),
          );
        } else {
          await repository.verifyPhoneCode(
            RegistrationValidators.normalizePhone(phoneController.text),
            verificationCodeController.text.trim(),
          );
        }
      } on RegistrationException catch (error) {
        verificationError = error.message;
        isVerifying = false;
        _notify();
        return false;
      } catch (_) {
        verificationError = 'Vérification impossible.';
        isVerifying = false;
        _notify();
        return false;
      }

      isVerifying = false;
    }
    isSubmitting = true;
    _notify();

    try {
      String? logoUrl;
      if (logoFile != null) {
        logoUrl = await repository.uploadLogo(File(logoFile!.path));
      }
      final payload = _buildPayload(logoUrl: logoUrl);
      await repository.submitRegistration(payload);
      isSubmitting = false;
      _notify();
      return true;
    } on RegistrationException catch (error) {
      submitError = error.message;
    } catch (_) {
      submitError = 'Inscription impossible. Réessayez.';
    }

    isSubmitting = false;
    _notify();
    return false;
  }

  Future<void> saveDraft() async {
    final payload = _buildPayload(logoUrl: null);
    await repository.saveDraft(payload);
  }

  RegistrationPayload _buildPayload({String? logoUrl}) {
    return RegistrationPayload(
      owner: PersonalInfo(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phone: RegistrationValidators.normalizePhone(phoneController.text),
        password: passwordController.text,
        countryCity: countryCityController.text.trim(),
        currency: currency,
      ),
      restaurant: RestaurantInfo(
        name: restaurantNameController.text.trim(),
        address: restaurantAddressController.text.trim(),
        phone: RegistrationValidators.normalizePhone(
          restaurantPhoneController.text,
        ),
        tablesCount: configureTablesLater
            ? null
            : int.tryParse(tablesCountController.text.trim()),
        configureTablesLater: configureTablesLater,
        logoUrl: logoUrl,
        schedule: scheduleController.text.trim().isEmpty
            ? null
            : scheduleController.text.trim(),
      ),
      verificationMethod: verificationMethod,
    );
  }

  void goToStep(int index) {
    if (index <= currentStep) {
      currentStep = index;
      _notify();
    }
  }

  void goNext() {
    if (currentStep < 2) {
      currentStep += 1;
      _notify();
    }
  }

  void goBack() {
    if (currentStep > 0) {
      currentStep -= 1;
      _notify();
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendSeconds -= 1;
      if (resendSeconds <= 0) {
        timer.cancel();
        resendSeconds = 0;
      }
      _notify();
    });
  }

  bool _isTemporaryOtpBypassCodeValid() {
    if (!_isTemporaryOtpBypassContactMatched()) {
      return false;
    }
    final enteredCode = verificationCodeController.text.trim();
    return enteredCode.isNotEmpty &&
        enteredCode == AppFlags.temporaryOtpBypassCode;
  }

  bool _isTemporaryOtpBypassContactMatched() {
    if (!AppFlags.temporaryOtpBypassConfigured) {
      return false;
    }
    if (verificationMethod == VerificationMethod.email) {
      final configuredEmail = AppFlags.temporaryOtpBypassEmail;
      if (configuredEmail.isEmpty) {
        return false;
      }
      return emailController.text.trim().toLowerCase() == configuredEmail;
    }
    final configuredPhone = AppFlags.temporaryOtpBypassPhone;
    if (configuredPhone.isEmpty) {
      return false;
    }
    final currentPhone = RegistrationValidators.normalizePhone(
      phoneController.text,
    );
    return currentPhone == configuredPhone;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    countryCityController.dispose();
    restaurantNameController.dispose();
    restaurantAddressController.dispose();
    restaurantPhoneController.dispose();
    tablesCountController.dispose();
    scheduleController.dispose();
    verificationCodeController.dispose();
    super.dispose();
  }
}
