import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/core/constants/india_geography.dart';

void main() {
  test('typing i or in suggests India first', () {
    expect(
      IndiaGeography.filterOptions(IndiaGeography.countries, 'i').first,
      'India',
    );
    expect(
      IndiaGeography.filterOptions(IndiaGeography.countries, 'in').first,
      'India',
    );
  });

  test('state and district suggestions cascade', () {
    expect(
      IndiaGeography.filterOptions(IndiaGeography.states, 'kar').first,
      'Karnataka',
    );
    final districts = IndiaGeography.districtsFor(state: 'Karnataka');
    expect(
      IndiaGeography.filterOptions(districts, 'ben').first,
      'Bengaluru Urban',
    );
  });
}
