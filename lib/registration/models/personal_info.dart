class PersonalInfo {
  const PersonalInfo({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.countryCity,
    required this.currency,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String countryCity;
  final String currency;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'countryCity': countryCity,
        'currency': currency,
      };
}
