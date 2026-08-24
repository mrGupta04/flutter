import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/doctor_registration/data/medical_specialities.dart';

void main() {
  test('gen ranks General specialities ahead of Emergency Medicine', () {
    final results = filterMedicalSpecialities('gen');
    final names = results.map((speciality) => speciality.name).toList();

    expect(names, isNot(contains('Emergency Medicine')));
    expect(names.take(3), [
      'General Physician',
      'General Medicine',
      'General Surgery',
    ]);
  });

  test('word-prefix still finds Emergency via title or subtitle', () {
    expect(
      filterMedicalSpecialities('emer').map((s) => s.name),
      contains('Emergency Medicine'),
    );
    expect(
      filterMedicalSpecialities('urg').map((s) => s.name),
      contains('Emergency Medicine'),
    );
  });

  test('catalog puts common specialities first', () {
    final names =
        filterMedicalSpecialities('').map((speciality) => speciality.name).toList();
    expect(names.take(4), [
      'General Physician',
      'General Medicine',
      'Cardiology',
      'Neurology',
    ]);
    expect(names, hasLength(medicalSpecialities.length));
  });
}
