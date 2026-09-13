import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqException implements Exception {
  final String message;
  final bool isMissingKey;

  const GroqException(this.message, {this.isMissingKey = false});

  @override
  String toString() => message;
}

class GroqService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Primary and fallback model hierarchy on Groq.
  static const List<String> availableModels = [
    'openai/gpt-oss-120b',
    'qwen/qwen3.8-27b',
    'groq/compound',
  ];
  static const String defaultModel = 'openai/gpt-oss-120b';

  /// Resolves the Groq API key strictly from:
  /// 1. .env file (GROQ_API_KEY)
  /// 2. Compile-time environment definition (--dart-define=GROQ_API_KEY=...)
  static String? getApiKey() {
    try {
      final envKey = dotenv.env['GROQ_API_KEY']?.trim();
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    } catch (_) {}

    const defineKey = String.fromEnvironment('GROQ_API_KEY');
    if (defineKey.trim().isNotEmpty) {
      return defineKey.trim();
    }

    return null;
  }

  /// Checks if the Groq API key is present in .env or environment.
  static bool hasApiKey() {
    final key = getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Performs an AI-assisted engineering review analysis of a sub-step.
  static Future<String> analyzeSubStep({
    required String projectName,
    required String stageName,
    String? stageDescription,
    required String checklistItem,
    required String itemDescription,
    required String discipline,
    String? existingNotes,
  }) async {
    final apiKey = getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const GroqException(
        'Groq API key not configured. Please add GROQ_API_KEY to your .env file.',
        isMissingKey: true,
      );
    }

    final promptBuffer = StringBuffer();
    promptBuffer.writeln('Review the following engineering checklist item for a product engineering project:');
    promptBuffer.writeln('• Project: $projectName');
    promptBuffer.writeln('• Stage: $stageName');
    if (stageDescription != null && stageDescription.isNotEmpty) {
      promptBuffer.writeln('• Stage Objective: $stageDescription');
    }
    promptBuffer.writeln('• Checklist Item: $checklistItem');
    if (itemDescription.isNotEmpty) {
      promptBuffer.writeln('• Item Description: $itemDescription');
    }
    if (discipline.isNotEmpty) {
      promptBuffer.writeln('• Lead Discipline: $discipline');
    }
    if (existingNotes != null && existingNotes.trim().isNotEmpty) {
      promptBuffer.writeln('• Existing Team Notes: ${existingNotes.trim()}');
    }

    promptBuffer.writeln();
    promptBuffer.writeln(
      'CRITICAL INSTRUCTIONS:\n'
      '- DO NOT output markdown tables (no pipes "|" or dashed table rows).\n'
      '- DO NOT output conversational filler, preambles, or concluding remarks.\n'
      '- Structure your response under these exact 4 section headers:\n\n'
      '### 1. KEY VERIFICATION CHECKS\n'
      '• **[Item Name]**: [Concise, measurable acceptance criteria and verification method]\n\n'
      '### 2. RISKS & FAILURE MODES\n'
      '• **[Failure Mode/Risk]**: [Likely cause, severity, and preventive check]\n\n'
      '### 3. RECOMMENDED EVIDENCE\n'
      '• **[Document/Artifact]**: [Specific calculations, CAD/simulation files, or test reports to attach]\n\n'
      '### 4. RECOMMENDED NEXT ACTIONS\n'
      '• **[Action Item]**: [Immediate tactical step to close or advance this item]\n\n'
      'Provide 3-4 bullet points per section. Keep it crisp, rigorous, and directly useful as engineering review notes.',
    );

    final client = http.Client();
    try {
      String lastError = '';
      for (final modelName in availableModels) {
        final payload = {
          'model': modelName,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a senior engineering design review specialist and systems engineer. '
                  'Provide concise, high-density, professional technical review notes. '
                  'Never output markdown tables or pleasantries.',
            },
            {
              'role': 'user',
              'content': promptBuffer.toString(),
            },
          ],
          'temperature': 0.2,
          'max_tokens': 1200,
        };

        final response = await client
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes))
              as Map<String, dynamic>;
          final choices = decoded['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              return content.trim();
            }
          }
          continue;
        } else if (response.statusCode == 401) {
          throw const GroqException(
            'Invalid Groq API key in .env (401 Unauthorized). Please check your key.',
            isMissingKey: true,
          );
        } else if (response.statusCode == 429) {
          throw const GroqException(
            'Groq rate limit reached (429). Please wait a moment and try again.',
          );
        } else if (response.statusCode == 404 || response.statusCode == 400) {
          try {
            final errJson = jsonDecode(response.body) as Map<String, dynamic>;
            final errCode = errJson['error']?['code'];
            final errMsg = errJson['error']?['message']?.toString() ?? '';
            lastError = errMsg;
            if (errCode == 'model_not_found' || errMsg.contains('model')) {
              continue; // try next candidate model
            }
          } catch (_) {}
          throw GroqException(
            'Groq API error (${response.statusCode}): $lastError',
          );
        } else {
          String serverMsg = 'Server status ${response.statusCode}';
          try {
            final errJson = jsonDecode(response.body) as Map<String, dynamic>;
            if (errJson['error']?['message'] != null) {
              serverMsg = errJson['error']['message'].toString();
            }
          } catch (_) {}
          throw GroqException('Groq API error: $serverMsg');
        }
      }

      throw GroqException(
        lastError.isNotEmpty
            ? 'Groq API error: $lastError'
            : 'Unable to get response from available Groq models.',
      );
    } on SocketException {
      throw const GroqException(
        'Network error: Unable to reach Groq API. Please check your internet connection.',
      );
    } on TimeoutException {
      throw const GroqException(
        'Groq request timed out. Please check your connection and try again.',
      );
    } on http.ClientException catch (e) {
      throw GroqException('Network error: ${e.message}');
    } on FormatException {
      throw const GroqException('Failed to process response from Groq.');
    } finally {
      client.close();
    }
  }
}
