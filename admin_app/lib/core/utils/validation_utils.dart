import 'dart:math';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

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

  /// Validate phone number (Indian format)
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Mobile number is required';
    }
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\D'), ''))) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
    if (name.length < AppConstants.minNameLength) {
      return 'Name must be at least ${AppConstants.minNameLength} characters';
    }
    if (name.length > AppConstants.maxNameLength) {
      return 'Name must be less than ${AppConstants.maxNameLength} characters';
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
}

/// Formatting utilities
class FormattingUtils {
  FormattingUtils._();

  /// Format phone number
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    return phone;
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
