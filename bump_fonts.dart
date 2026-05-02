// One-shot migration: bump every Tajawal font size by +2 across the app.
//
// Targets common patterns:
//   fontSize: 14.0
//   fontSize: 14
//   fontSize: 14.0 * scale
//   fontSize: 14.0 * scale * fontScale
//   fontSize: 11.0 * scale * (Localizations... ? 1.15 : 1.0)
//
// Only edits files that import google_fonts (so we don't accidentally
// touch unrelated TextStyle blocks elsewhere).
//
// Run from repo root:  dart run bump_fonts.dart
//                      dart run bump_fonts.dart --by=4   (custom delta)
//                      dart run bump_fonts.dart --dry    (preview only)

import 'dart:io';

void main(List<String> args) {
  var delta = 2.0;
  var dryRun = false;
  for (final arg in args) {
    if (arg == '--dry') dryRun = true;
    if (arg.startsWith('--by=')) {
      delta = double.tryParse(arg.substring(5)) ?? 2.0;
    }
  }

  final dir = Directory('lib');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  // Match `fontSize: <number>` where <number> is a literal like 14 or 14.0.
  // The trailing context ([,*\s\)]) keeps us off identifier matches like
  // `fontSize: scale` (no literal to bump).
  final pattern = RegExp(
    r'fontSize:\s*([0-9]+(?:\.[0-9]+)?)([\s,\)\*])',
  );

  var changedFiles = 0;
  var totalReplacements = 0;

  for (final file in files) {
    final original = file.readAsStringSync();
    if (!original.contains('google_fonts')) continue;
    if (!original.contains('fontSize:')) continue;

    var fileReplacements = 0;
    final updated = original.replaceAllMapped(pattern, (m) {
      final raw = m.group(1)!;
      final trailing = m.group(2)!;
      final value = double.parse(raw);
      final bumped = value + delta;
      // Preserve `.0` style if original had it; otherwise emit clean number.
      final bumpedStr = raw.contains('.')
          ? bumped.toStringAsFixed(1)
          : bumped.toStringAsFixed(0);
      fileReplacements++;
      return 'fontSize: $bumpedStr$trailing';
    });

    if (fileReplacements > 0) {
      if (!dryRun) file.writeAsStringSync(updated);
      changedFiles++;
      totalReplacements += fileReplacements;
      stdout.writeln('  ${file.path}: $fileReplacements');
    }
  }

  final action = dryRun ? 'Would replace' : 'Replaced';
  stdout.writeln(
    '$action $totalReplacements fontSize values (+$delta) across $changedFiles files.',
  );
}
