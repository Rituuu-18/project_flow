import 'dart:io';

void main() {
  final content = File('lib/features/reviews/domain/utils/default_stages.dart').readAsStringSync();
  final exp = RegExp(r"'([^']+)'\s*:\s*SubStepDefaultInfo\(");
  final matches = exp.allMatches(content);
  print('Total sub-steps in default_stages.dart: ${matches.length}');
}
