import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/core/utils/validation_utils.dart';

void main() {
  test('rejects a 17-digit phone number', () {
    expect(
      ValidationUtils.validateOptionalPhone('99453455466446466'),
      'Mobile number must be exactly 10 digits',
    );
  });

  test('accepts a valid Indian mobile number', () {
    expect(ValidationUtils.validateOptionalPhone('9876543210'), isNull);
  });

  test('requires a valid employee ID and email', () {
    expect(ValidationUtils.validateEmployeeId('12'), isNotNull);
    expect(ValidationUtils.validateEmployeeId('EMP-7676'), isNull);
    expect(ValidationUtils.validateEmail('not-an-email'), isNotNull);
    expect(ValidationUtils.validateEmail('Testing1@gmail.com'), isNull);
  });

  test('password must include upper, number, and special character', () {
    expect(ValidationUtils.validatePassword('password'), isNotNull);
    expect(ValidationUtils.validatePassword('Admin@123'), isNull);
  });
}
