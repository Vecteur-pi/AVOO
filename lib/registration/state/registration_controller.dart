import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/personal_info.dart';
import '../models/registration_payload.dart';
import '../models/restaurant_info.dart';
import '../models/verification_method.dart';
import '../services/registration_repository.dart';

class RegistrationValidators {
  static final RegExp _phoneRegExp = RegExp(r'^\+[1-9]\d{7,14}$');
  static final RegExp _passwordRegExp = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$');

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir votre nom et prénom.';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Veuillez saisir nom et prénom.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir votre e-mail.';
    }
    final email = value.trim();
    final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegExp.hasMatch(email)) {
      return 'Veuillez saisir un e-mail valide.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir votre numéro de téléphone.';
    }
    final normalized = normalizePhone(value);
    if (!_phoneRegExp.hasMatch(normalized)) {
      return 'Utilisez le format international, ex: +24161234567.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe.';
    }
    if (!_passwordRegExp.hasMatch(value)) {
      return 'Min. 8 caractères, 1 majuscule et 1 chiffre.';
    }
    return null;
  }

  static String? countryCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir le pays et la ville.';
    }
    return null;
  }

  static String? currency(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez sélectionner une devise.';
    }
    return null;
  }

  static String? restaurantName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir le nom du restaurant.';
    }
    return null;
  }

  static String? restaurantAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir l\'adresse ou quartier.';
    }
    return null;
  }

  static String? restaurantPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir le téléphone du restaurant.';
    }
    final normalized = normalizePhone(value);
    if (!_phoneRegExp.hasMatch(normalized)) {
      return 'Utilisez le format international, ex: +24161234567.';
    }
    return null;
  }

  static String? tablesCount(String? value, bool configureLater) {
    if (configureLater) {
      return null;
    }
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir le nombre de tables.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Entrez un nombre valide.';
    }
    return null;
  }

  static String? verificationCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir le code.';
    }
    if (value.trim().length < 4) {
      return 'Le code est trop court.';
    }
    return null;
  }

  static String normalizePhone(String value) {
    return value.replaceAll(' ', '').trim();
  }
}

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
        RegistrationValidators.countryCity(countryCityController.text) == null &&
        RegistrationValidators.currency(currency) == null &&
        emailUniqueError == null &&
        phoneUniqueError == null &&
        !isCheckingUnique;
  }

  bool get canProceedStep2 {
    return RegistrationValidators.restaurantName(restaurantNameController.text) ==
            null &&
        RegistrationValidators.restaurantAddress(
              restaurantAddressController.text,
            ) ==
            null &&
        RegistrationValidators.restaurantPhone(restaurantPhoneController.text) ==
            null &&
        RegistrationValidators.tablesCount(
              tablesCountController.text,
              configureTablesLater,
            ) ==
            null;
  }

  bool get canSubmit {
    return RegistrationValidators.verificationCode(
              verificationCodeController.text,
            ) ==
            null &&
        !isVerifying &&
        !isSubmitting;
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
    if (form == null || !form.validate()) {
      return false;
    }

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
