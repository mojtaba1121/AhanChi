import 'package:ahanchi/core/input_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Iran mobile validation', () {
    test('normalizes Persian and Arabic digits', () {
      expect(normalizeIranMobile('۰۹۱۲۳۴۵۶۷۸۹'), '09123456789');
      expect(normalizeIranMobile('٠٩١٢٣٤٥٦٧٨٩'), '09123456789');
    });

    test('normalizes the +98 country prefix', () {
      expect(normalizeIranMobile('+98 912 345 6789'), '09123456789');
    });

    test('returns specific required and format messages', () {
      expect(validateIranMobile(''), 'شماره موبایل الزامی است');
      expect(validateIranMobile('09123'), 'شماره باید با ۰۹ شروع شود و ۱۱ رقم باشد');
      expect(validateIranMobile('09123456789'), isNull);
    });
  });

  group('Password validation', () {
    test('requires at least eight characters', () {
      expect(validatePassword(''), 'رمز عبور الزامی است');
      expect(validatePassword('1234567'), 'رمز عبور باید حداقل ۸ کاراکتر باشد');
      expect(validatePassword('12345678'), isNull);
    });
  });

  group('Required location validation', () {
    test('requires a meaningful city and village name', () {
      expect(validateRequiredLocation('', 'نام شهر'), 'نام شهر الزامی است');
      expect(validateRequiredLocation('م', 'نام روستا'), 'نام روستا باید حداقل ۲ کاراکتر باشد');
      expect(validateRequiredLocation('مشهد', 'نام شهر'), isNull);
    });
  });
}
