import 'package:ahanchi/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('purchase calculations', () {
    test('converts decimal kilograms to integer grams', () {
      expect(kilogramsTextToGrams('25.400'), 25400);
      expect(kilogramsTextToGrams('0٫125'), 125);
    });

    test('calculates total amount in toman', () {
      expect(calculateTotal(25400, 18000), 457200);
    });

    test('rejects zero weight', () {
      expect(() => kilogramsTextToGrams('0'), throwsFormatException);
    });
  });
}
