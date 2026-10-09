import 'models.dart';

const _months = [
  'jan',
  'feb',
  'mar',
  'apr',
  'maj',
  'jun',
  'jul',
  'avg',
  'sep',
  'okt',
  'nov',
  'dec'
];
const _weekdays = [
  'ponedeljak',
  'utorak',
  'sreda',
  'četvrtak',
  'petak',
  'subota',
  'nedelja'
];
const weekdaysShort = ['pon', 'uto', 'sre', 'čet', 'pet', 'sub', 'ned'];

/// Srpski format: decimalni zarez.
String fmtD(double v, [int decimals = 1]) =>
    v.toStringAsFixed(decimals).replaceAll('.', ',');

/// Tačka za hiljade: 1.510
String fmtI(int v) {
  final s = v.abs().toString();
  final buf = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatDate(int epochDay) {
  final d = dateOf(epochDay);
  return '${d.day}. ${_months[d.month - 1]} ${d.year}.';
}

String formatShortDate(int epochDay) {
  final d = dateOf(epochDay);
  return '${d.day}. ${_months[d.month - 1]}';
}

String formatRelativeDay(int epochDay, int today) {
  if (epochDay == today) return 'Danas';
  if (epochDay == today - 1) return 'Juče';
  final name = _weekdays[dateOf(epochDay).weekday - 1];
  return '${name[0].toUpperCase()}${name.substring(1)}, ${formatShortDate(epochDay)}';
}

double? parseNumber(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

/// "1 nedelja / 2 nedelje / 5 nedelja"; [accusative] za "za 1 nedelju".
String weeksText(int n, {bool accusative = false}) {
  String word;
  if (n % 10 == 1 && n % 100 != 11) {
    word = accusative ? 'nedelju' : 'nedelja';
  } else if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 12 || n % 100 > 14)) {
    word = 'nedelje';
  } else {
    word = 'nedelja';
  }
  return '$n $word';
}

const _quotes = [
  'Mali koraci svaki dan prave velike promene. 🌷',
  'Budi nežna prema sebi — napredak nije uvek prava linija.',
  'Ti si svoj najlepši projekat. 💕',
  'Ne moraš biti savršena, dovoljno je da budeš dosledna.',
  'Svaka dobra odluka danas je poklon tebi sutra. ✨',
  'Ponosna budi na sebe što si danas ovde. 🌸',
  'Telo te sluša — govori mu lepo.',
  'Cvetaš svojim tempom. 🌼',
];

String quoteFor(int epochDay) => _quotes[epochDay % _quotes.length];
