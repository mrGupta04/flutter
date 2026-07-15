import 'dart:math';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/phone_countries.dart';

/// Validation utilities
class ValidationUtils {
  ValidationUtils._();

  /// Validate email format
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    if (password.length > AppConstants.maxPasswordLength) {
      return 'Password must be less than ${AppConstants.maxPasswordLength} characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Input formatters for mobile fields (10 digits for India).
  static List<TextInputFormatter> mobileInputFormatters({
    String countryCode = PhoneCountries.defaultDialCode,
  }) {
    final maxLength = countryCode == PhoneCountries.defaultDialCode ? 10 : 15;
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  /// Validate phone number with country code (India default).
  static String? validatePhoneNumber(
    String? phone, {
    String countryCode = PhoneCountries.defaultDialCode,
  }) {
    if (phone == null || phone.isEmpty) {
      return 'Mobile number is required';
    }
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (countryCode == PhoneCountries.defaultDialCode) {
      if (cleaned.length != 10) {
        return 'Mobile number must be exactly 10 digits';
      }
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
        return 'Please enter a valid 10-digit mobile number';
      }
      return null;
    }
    if (cleaned.length < 6 || cleaned.length > 15) {
      return 'Please enter a valid mobile number';
    }
    return null;
  }

  /// Format mobile with country code for display.
  static String formatInternationalPhone(
    String phone, {
    String countryCode = PhoneCountries.defaultDialCode,
  }) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return '';
    if (countryCode == PhoneCountries.defaultDialCode && cleaned.length == 10) {
      return '+$countryCode ${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    return '+$countryCode $cleaned';
  }

  /// Validate name
  static String? validateName(String? name, {String fieldName = 'Name'}) {
    if (name == null || name.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = name.trim();
    if (trimmed.length < AppConstants.minNameLength) {
      return '$fieldName must be at least ${AppConstants.minNameLength} characters';
    }
    if (trimmed.length > AppConstants.maxNameLength) {
      return '$fieldName must be less than ${AppConstants.maxNameLength} characters';
    }
    if (!RegExp(r"^[a-zA-Z.\s\-']+$").hasMatch(trimmed)) {
      return '$fieldName can only contain letters and spaces';
    }
    return null;
  }

  /// Clinic / company / council / bank name — allows digits and common symbols.
  static String? validateOrganizationName(
    String? name, {
    String fieldName = 'Name',
    int minLength = 2,
  }) {
    if (name == null || name.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = name.trim();
    if (trimmed.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (trimmed.length > 120) {
      return '$fieldName is too long';
    }
    if (!RegExp(r"^[a-zA-Z0-9.,&/\s\-']+$").hasMatch(trimmed)) {
      return 'Enter a valid $fieldName';
    }
    return null;
  }

  /// Validate medical registration number
  static String? validateMedicalRegNumber(String? regNumber) {
    if (regNumber == null || regNumber.isEmpty) {
      return 'Medical registration number is required';
    }
    if (regNumber.length < 5) {
      return 'Please enter a valid registration number';
    }
    return null;
  }

  /// Validate years of experience
  static String? validateYearsOfExperience(String? years) {
    if (years == null || years.isEmpty) {
      return 'Years of experience is required';
    }
    final yearsInt = int.tryParse(years);
    if (yearsInt == null) {
      return 'Please enter a valid number';
    }
    if (yearsInt < AppConstants.minYearsOfExperience) {
      return 'Years of experience cannot be negative';
    }
    if (yearsInt > AppConstants.maxYearsOfExperience) {
      return 'Please enter a valid years of experience';
    }
    return null;
  }

  /// Validate consultation fee
  static String? validateConsultationFee(String? fee) {
    if (fee == null || fee.isEmpty) {
      return 'Consultation fee is required';
    }
    final feeInt = int.tryParse(fee);
    if (feeInt == null) {
      return 'Please enter a valid fee';
    }
    if (feeInt <= 0) {
      return 'Consultation fee must be greater than 0';
    }
    if (feeInt > AppConstants.maxConsultationFee) {
      return 'Consultation fee is too high';
    }
    return null;
  }

  /// Validate address
  static String? validateAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Address is required';
    }
    if (address.length < 5) {
      return 'Please enter a valid address';
    }
    return null;
  }

  /// Validate pincode
  static String? validatePincode(String? pincode) {
    if (pincode == null || pincode.isEmpty) {
      return 'Pincode is required';
    }
    final pincodeRegex = RegExp(r'^[0-9]{6}$');
    if (!pincodeRegex.hasMatch(pincode)) {
      return 'Please enter a valid 6-digit pincode';
    }
    return null;
  }

  /// Check if passwords match
  static String? validatePasswordMatch(String? password, String? confirmPassword) {
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate 12-digit Aadhaar number
  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhaar number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return 'Enter a valid 12-digit Aadhaar number';
    }
    if (RegExp(r'^(\d)\1{11}$').hasMatch(cleaned)) {
      return 'Enter a valid Aadhaar number';
    }
    return null;
  }

  /// Validate 6-digit OTP
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter the 6-digit OTP';
    }
    return null;
  }

  /// Validate bank account number (9–18 digits)
  static String? validateAccountNumber(String? account) {
    if (account == null || account.isEmpty) {
      return 'Account number is required';
    }
    final cleaned = account.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{9,18}$').hasMatch(cleaned)) {
      return 'Enter a valid account number (9–18 digits)';
    }
    return null;
  }

  /// Validate Indian UPI ID (e.g. name@oksbi, 9876543210@paytm)
  static String? validateUpiId(String? upi) {
    if (upi == null || upi.isEmpty) {
      return 'UPI ID is required';
    }
    final cleaned = upi.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9.\-_]{2,256}@[a-z]{2,64}$').hasMatch(cleaned)) {
      return 'Enter a valid UPI ID (e.g. yourname@oksbi)';
    }
    return null;
  }

  /// Validate Indian IFSC code (e.g. HDFC0001234)
  static String? validateIfscCode(String? ifsc) {
    if (ifsc == null || ifsc.isEmpty) {
      return 'IFSC code is required';
    }
    final cleaned = ifsc.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(cleaned)) {
      return 'Enter a valid 11-character IFSC code';
    }
    return null;
  }

  /// Validate bio/about
  static String? validateBio(String? bio) {
    if (bio == null || bio.isEmpty) {
      return null; // Optional field
    }
    if (bio.length < AppConstants.minBioLength) {
      return 'Bio must be at least ${AppConstants.minBioLength} characters';
    }
    if (bio.length > AppConstants.maxBioLength) {
      return 'Bio must be less than ${AppConstants.maxBioLength} characters';
    }
    return null;
  }

  /// Required non-empty text with optional min length.
  static String? validateRequired(
    String? value, {
    String fieldName = 'This field',
    int minLength = 1,
    int? maxLength,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (maxLength != null && trimmed.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  /// City name (letters, spaces, hyphens, periods).
  static String? validateCity(String? city) {
    if (city == null || city.trim().isEmpty) {
      return 'City is required';
    }
    final trimmed = city.trim();
    if (trimmed.length < 2) {
      return 'Enter a valid city name';
    }
    if (!RegExp(r"^[a-zA-Z.\s\-']{2,60}$").hasMatch(trimmed)) {
      return 'City can only contain letters and spaces';
    }
    return null;
  }

  /// State name.
  static String? validateState(String? state) {
    if (state == null || state.trim().isEmpty) {
      return 'State is required';
    }
    final trimmed = state.trim();
    if (trimmed.length < 2) {
      return 'Enter a valid state name';
    }
    if (!RegExp(r"^[a-zA-Z.\s\-']{2,60}$").hasMatch(trimmed)) {
      return 'State can only contain letters and spaces';
    }
    return null;
  }

  /// Optional email — validates format only when provided.
  static String? validateOptionalEmail(String? email) {
    if (email == null || email.trim().isEmpty) return null;
    return validateEmail(email);
  }

  /// Optional phone — validates format only when provided.
  static String? validateOptionalPhone(
    String? phone, {
    String countryCode = PhoneCountries.defaultDialCode,
  }) {
    if (phone == null || phone.trim().isEmpty) return null;
    return validatePhoneNumber(phone, countryCode: countryCode);
  }

  /// Optional UPI — validates format only when provided.
  static String? validateOptionalUpiId(String? upi) {
    if (upi == null || upi.trim().isEmpty) return null;
    return validateUpiId(upi);
  }

  /// Optional GSTIN — validates format only when provided.
  static String? validateOptionalGstin(String? gstin) =>
      validateGstin(gstin, required: false);

  /// Indian GSTIN (15 characters).
  static String? validateGstin(String? gstin, {bool required = true}) {
    if (gstin == null || gstin.trim().isEmpty) {
      return required ? 'GSTIN is required' : null;
    }
    final cleaned = gstin.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (!RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    ).hasMatch(cleaned)) {
      return 'Enter a valid 15-character GSTIN';
    }
    return null;
  }

  /// Indian PAN (e.g. ABCDE1234F).
  static String? validatePan(String? pan, {bool required = true}) {
    if (pan == null || pan.trim().isEmpty) {
      return required ? 'PAN is required' : null;
    }
    final cleaned = pan.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(cleaned)) {
      return 'Enter a valid PAN (e.g. ABCDE1234F)';
    }
    return null;
  }

  /// Bank / account holder name.
  static String? validateBankName(String? name) {
    return validateRequired(name, fieldName: 'Bank name', minLength: 2);
  }

  static String? validateAccountHolderName(String? name) {
    return validateRequired(
      name,
      fieldName: 'Account holder name',
      minLength: 2,
    );
  }

  /// Indian vehicle registration plate (e.g. MH12AB1234 / MH-12-AB-1234).
  static String? validateVehicleRegistration(String? plate) {
    if (plate == null || plate.trim().isEmpty) {
      return 'Vehicle registration number is required';
    }
    final cleaned =
        plate.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    if (!RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{0,3}[0-9]{4}$').hasMatch(cleaned)) {
      return 'Enter a valid vehicle number (e.g. MH12AB1234)';
    }
    return null;
  }

  /// Indian driving licence number (basic format check).
  static String? validateDrivingLicense(String? license) {
    if (license == null || license.trim().isEmpty) {
      return 'Driving licence number is required';
    }
    final cleaned =
        license.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    if (cleaned.length < 8 || cleaned.length > 20) {
      return 'Enter a valid driving licence number';
    }
    if (!RegExp(r'^[A-Z0-9]{8,20}$').hasMatch(cleaned)) {
      return 'Driving licence can only contain letters and numbers';
    }
    return null;
  }

  /// Generic license / registration / org ID.
  static String? validateLicenseNumber(
    String? value, {
    String fieldName = 'License number',
    int minLength = 4,
  }) {
    return validateRequired(
      value,
      fieldName: fieldName,
      minLength: minLength,
      maxLength: 40,
    );
  }

  /// Year of establishment or vehicle manufacture.
  static String? validateYear(
    String? year, {
    String fieldName = 'Year',
    int minYear = 1950,
  }) {
    if (year == null || year.trim().isEmpty) {
      return '$fieldName is required';
    }
    final y = int.tryParse(year.trim());
    final current = DateTime.now().year;
    if (y == null) {
      return 'Enter a valid $fieldName';
    }
    if (y < minYear || y > current) {
      return '$fieldName must be between $minYear and $current';
    }
    return null;
  }

  /// Date of birth — person must be at least [minAge] years old.
  static String? validateDateOfBirth(
    String? value, {
    int minAge = 18,
    int maxAge = 100,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Date of birth is required';
    }
    final parsed = DateTime.tryParse(value.trim()) ??
        _tryParseDisplayDate(value.trim());
    if (parsed == null) {
      return 'Enter a valid date of birth';
    }
    final now = DateTime.now();
    if (parsed.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }
    var age = now.year - parsed.year;
    if (now.month < parsed.month ||
        (now.month == parsed.month && now.day < parsed.day)) {
      age--;
    }
    if (age < minAge) {
      return 'You must be at least $minAge years old';
    }
    if (age > maxAge) {
      return 'Enter a valid date of birth';
    }
    return null;
  }

  /// Expiry / future-or-today date (yyyy-MM-dd or dd MMM yyyy).
  static String? validateFutureOrTodayDate(
    String? value, {
    String fieldName = 'Date',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = DateTime.tryParse(value.trim()) ??
        _tryParseDisplayDate(value.trim());
    if (parsed == null) {
      return 'Enter a valid $fieldName';
    }
    final today = DateTime.now();
    final dayOnly = DateTime(parsed.year, parsed.month, parsed.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (dayOnly.isBefore(todayOnly)) {
      return '$fieldName cannot be in the past';
    }
    return null;
  }

  /// Positive number with optional max (fees, capacity, radius, discount).
  static String? validatePositiveNumber(
    String? value, {
    String fieldName = 'Value',
    num min = 1,
    num? max,
    bool allowDecimal = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final n = allowDecimal
        ? double.tryParse(value.trim())
        : int.tryParse(value.trim());
    if (n == null) {
      return 'Enter a valid $fieldName';
    }
    if (n < min) {
      return '$fieldName must be at least $min';
    }
    if (max != null && n > max) {
      return '$fieldName must be at most $max';
    }
    return null;
  }

  static DateTime? _tryParseDisplayDate(String value) {
    try {
      return DateFormat('dd MMM yyyy').parseStrict(value);
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(value);
      } catch (_) {
        return null;
      }
    }
  }
}

/// Formatting utilities
class FormattingUtils {
  FormattingUtils._();

  /// Format phone number
  static String formatPhoneNumber(
    String phone, {
    String countryCode = PhoneCountries.defaultDialCode,
  }) {
    return ValidationUtils.formatInternationalPhone(
      phone,
      countryCode: countryCode,
    );
  }

  /// Format date
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date with day
  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEE, dd MMM yyyy').format(date);
  }

  /// Format time
  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  /// Format consultation fee
  static String formatConsultationFee(int fee) {
    return '₹$fee';
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Format years of experience
  static String formatExperience(int years) {
    if (years == 1) return '$years year';
    return '$years years';
  }
}


/// Parse convenience
extension NumFormatting on num {
  /// Convert to currency string
  String toCurrency() => '₹${toStringAsFixed(0)}';

  /// Convert to percentage string
  String toPercentage() => '${(this * 100).toStringAsFixed(1)}%';
}
