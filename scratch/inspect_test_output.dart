import 'dart:convert';
import 'dart:io';

void main() {
  final content = File('test_output.pdf').readAsStringSync(encoding: latin1);
  for (final chunk in content.split('endobj')) {
    if (chunk.contains('/Link') || chunk.contains('/URI')) {
      print('--- OBJ ---');
      print(chunk.trim());
    }
  }
}
