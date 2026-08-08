import 'package:intl/intl.dart';

final _number = NumberFormat.decimalPattern('fa');

String toman(int value) => '${_number.format(value)} تومان';
String weight(int grams) => grams >= 1000
    ? '${_number.format(grams / 1000)} کیلوگرم'
    : '${_number.format(grams)} گرم';

int kilogramsTextToGrams(String value) {
  final normalized = value.replaceAll('٫', '.').replaceAll(',', '').trim();
  final kg = double.parse(normalized);
  if (kg <= 0) throw const FormatException('وزن باید بیشتر از صفر باشد');
  return (kg * 1000).round();
}

int calculateTotal(int weightGrams, int pricePerKgToman) =>
    (weightGrams * pricePerKgToman / 1000).round();
