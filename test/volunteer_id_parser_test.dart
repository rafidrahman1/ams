import 'package:asset_management_system/core/utils/volunteer_id_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeVolunteerId accepts plain volunteer id', () {
    expect(normalizeVolunteerId('VOL-1001'), 'VOL-1001');
  });

  test('normalizeVolunteerId extracts volunteer_id from JSON', () {
    expect(normalizeVolunteerId('{"volunteer_id":"VOL-1001"}'), 'VOL-1001');
  });

  test('normalizeVolunteerId extracts nested volunteer_data', () {
    expect(
      normalizeVolunteerId('{"volunteer_data":{"volunteer_id":"VOL-1001","email":"a@b.com"}}'),
      'VOL-1001',
    );
  });

  test('normalizeVolunteerId extracts volunteer_id from URL', () {
    expect(
      normalizeVolunteerId('https://ams.example.com/login?volunteer_id=VOL-1001'),
      'VOL-1001',
    );
  });

  test('normalizeVolunteerId rejects asset JSON without volunteer id', () {
    expect(normalizeVolunteerId('{"ast_ID":"AST-000001"}'), isNull);
  });

  test('normalizeVolunteerId rejects empty values', () {
    expect(normalizeVolunteerId(null), isNull);
    expect(normalizeVolunteerId('   '), isNull);
  });
}
