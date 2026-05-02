// One-shot migration: swap every GoogleFonts.<name> reference to
// GoogleFonts.tajawal so the whole app renders in Tajawal.
//
// Handles both call form `GoogleFonts.poppins(` and tear-off form
// `(isRTL ? GoogleFonts.cairo : GoogleFonts.lexendDeca)(`.
//
// Run from repo root:  dart run replace_fonts.dart
// Safe to re-run.

import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  // Methods on GoogleFonts that are NOT font getters.
  const nonFontMembers = {'config', 'asMap', 'pendingFonts'};

  // Match GoogleFonts.<methodName> — both call form and tear-off form.
  final pattern = RegExp(r'GoogleFonts\.([a-zA-Z][a-zA-Z0-9_]*)');

  var changedFiles = 0;
  var totalReplacements = 0;

  for (final file in files) {
    final original = file.readAsStringSync();
    if (!original.contains('GoogleFonts.')) continue;

    var fileReplacements = 0;
    final updated = original.replaceAllMapped(pattern, (m) {
      final method = m.group(1)!;
      if (method == 'tajawal') return m.group(0)!;
      if (nonFontMembers.contains(method)) return m.group(0)!;
      fileReplacements++;
      return 'GoogleFonts.tajawal';
    });

    if (fileReplacements > 0) {
      file.writeAsStringSync(updated);
      changedFiles++;
      totalReplacements += fileReplacements;
      stdout.writeln('  ${file.path}: $fileReplacements');
    }
  }

  stdout.writeln('Done — $totalReplacements replacements across $changedFiles files.');
}
