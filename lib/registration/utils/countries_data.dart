class CountryData {
  final String name;
  final String code;
  final String dialCode;

  const CountryData({
    required this.name,
    required this.code,
    required this.dialCode,
  });
}

// A curated list of common countries, focusing particularly on Francophone Africa and major global countries to keep it lightweight.
const List<CountryData> commonCountries = [
  CountryData(name: 'Gabon', code: 'GA', dialCode: '+241'),
  CountryData(name: 'Sénégal', code: 'SN', dialCode: '+221'),
  CountryData(name: 'Côte d\'Ivoire', code: 'CI', dialCode: '+225'),
  CountryData(name: 'Cameroun', code: 'CM', dialCode: '+237'),
  CountryData(name: 'Mali', code: 'ML', dialCode: '+223'),
  CountryData(name: 'Bénin', code: 'BJ', dialCode: '+229'),
  CountryData(name: 'Togo', code: 'TG', dialCode: '+228'),
  CountryData(name: 'Burkina Faso', code: 'BF', dialCode: '+226'),
  CountryData(name: 'Congo', code: 'CG', dialCode: '+242'),
  CountryData(name: 'RD Congo', code: 'CD', dialCode: '+243'),
  CountryData(name: 'Maroc', code: 'MA', dialCode: '+212'),
  CountryData(name: 'Algérie', code: 'DZ', dialCode: '+213'),
  CountryData(name: 'Tunisie', code: 'TN', dialCode: '+216'),
  CountryData(name: 'France', code: 'FR', dialCode: '+33'),
  CountryData(name: 'Belgique', code: 'BE', dialCode: '+32'),
  CountryData(name: 'Suisse', code: 'CH', dialCode: '+41'),
  CountryData(name: 'Canada', code: 'CA', dialCode: '+1'),
  CountryData(name: 'États-Unis', code: 'US', dialCode: '+1'),
];
