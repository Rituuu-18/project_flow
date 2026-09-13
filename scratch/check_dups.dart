import 'dart:io';

void main() {
  final content = File('lib/features/reviews/domain/utils/default_stages.dart').readAsStringSync();
  final exp = RegExp(r"'([^']+)'\s*:\s*SubStepDefaultInfo\(");
  final matches = exp.allMatches(content);
  final names = matches.map((m) => m.group(1)).toList();
  final seen = <String>{};
  for (final name in names) {
    if (seen.contains(name)) {
      print('DUPLICATE SUBSTEP NAME: $name');
    }
    seen.add(name!);
  }
}
