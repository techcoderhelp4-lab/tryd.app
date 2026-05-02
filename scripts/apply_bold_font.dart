import 'dart:io';

void main() {
  final directory = Directory('lib');
  if (!directory.existsSync()) {
    print('Directory "lib" not found.');
    return;
  }

  int filesUpdated = 0;

  directory.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      
      // We apply replacements in reverse order of weight to avoid double-bumping
      // e.g. if we changed w400 -> w500 first, then a second pass would change that w500 to w600.
      
      String newContent = content;
      
      // Update Weights
      newContent = newContent.replaceAll('FontWeight.w700', 'FontWeight.w800');
      newContent = newContent.replaceAll('FontWeight.w600', 'FontWeight.w700');
      newContent = newContent.replaceAll('FontWeight.w500', 'FontWeight.w600');
      newContent = newContent.replaceAll('FontWeight.w400', 'FontWeight.w500');
      
      // Also handle FontWeight.normal (alias for w400)
      newContent = newContent.replaceAll('FontWeight.normal', 'FontWeight.w500');
      
      // Also handle FontWeight.bold (alias for w700)
      newContent = newContent.replaceAll('FontWeight.bold', 'FontWeight.w800');

      if (newContent != content) {
        entity.writeAsStringSync(newContent);
        filesUpdated++;
        print('Updated: ${entity.path}');
      }
    }
  });

  print('\nDone! Updated $filesUpdated files.');
  print('The font weights have been shifted up by one step (e.g. w400 -> w500).');
}
