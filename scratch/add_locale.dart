import 'dart:io';

void main() {
  final file = File('lib/core/localization/translations.dart');
  final content = file.readAsStringSync();

  final regex = RegExp(r"  'en': \{(.*?)\n  \},", dotAll: true);
  final match = regex.firstMatch(content);
  
  if (match != null) {
    final deBlock = "\n  'de': {" + match.group(1)! + "\n  },";
    final newContent = content.replaceFirst('\n};\n', deBlock + '\n};\n');
    file.writeAsStringSync(newContent);
    print("Added 'de' locale structure to translations.dart");
  } else {
    print("Could not find 'en' block");
  }
}
