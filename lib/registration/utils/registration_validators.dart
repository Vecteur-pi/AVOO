import '../state/registration_controller.dart';

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
