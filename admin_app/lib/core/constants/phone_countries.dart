class PhoneCountry {
  final String name;
  final String dialCode;
  final String flag;

  const PhoneCountry({
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  String get displayLabel => '$flag +$dialCode';
}

class PhoneCountries {
  PhoneCountries._();

  static const defaultDialCode = '91';

  static const List<PhoneCountry> supported = [
    PhoneCountry(name: 'India', dialCode: '91', flag: '🇮🇳'),
    PhoneCountry(name: 'United States', dialCode: '1', flag: '🇺🇸'),
    PhoneCountry(name: 'United Kingdom', dialCode: '44', flag: '🇬🇧'),
    PhoneCountry(name: 'United Arab Emirates', dialCode: '971', flag: '🇦🇪'),
    PhoneCountry(name: 'Singapore', dialCode: '65', flag: '🇸🇬'),
    PhoneCountry(name: 'Australia', dialCode: '61', flag: '🇦🇺'),
    PhoneCountry(name: 'Canada', dialCode: '1', flag: '🇨🇦'),
  ];

  static PhoneCountry get defaultCountry => supported.first;

  static PhoneCountry findByDialCode(String dialCode) {
    final cleaned = dialCode.replaceAll(RegExp(r'\D'), '');
    return supported.firstWhere(
      (c) => c.dialCode == cleaned,
      orElse: () => defaultCountry,
    );
  }
}
