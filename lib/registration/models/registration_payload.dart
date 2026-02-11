import 'personal_info.dart';
import 'restaurant_info.dart';
import 'verification_method.dart';

class RegistrationPayload {
  const RegistrationPayload({
    required this.owner,
    required this.restaurant,
    required this.verificationMethod,
  });

  final PersonalInfo owner;
  final RestaurantInfo restaurant;
  final VerificationMethod verificationMethod;

  Map<String, dynamic> toJson() => {
        'owner': owner.toJson(),
        'restaurant': restaurant.toJson(),
        'verificationMethod': verificationMethod.name,
      };
}
