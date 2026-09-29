import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../features/workspace/domain/entities/engineering_report.dart';
import 'engineering_report_prompt.dart';

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
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'qwen/qwen3.8-27b',
    'groq/compound',
  ];
  static const String defaultModel = 'openai/gpt-oss-120b';

  static String engineeringInstructionsFor(String checklistItem) =>
      EngineeringReportPrompt.forChecklist(checklistItem);

  static String buildAnalysisPrompt({
    required String projectName,
    required String checklistItem,
    required String itemDescription,
  }) {
    final name = projectName.trim();
    final item = checklistItem.trim();
    final description = itemDescription.trim();
    if (name.isEmpty) {
      throw const GroqException('A project name is required for AI analysis.');
    }
    if (item.isEmpty || description.isEmpty) {
      throw const GroqException(
        'A checklist item and its description are required for AI analysis.',
      );
    }

    return 'Project name: $name\n'
        'Checklist item: $item\n'
        'Checklist description: $description';
  }

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
    required String checklistItem,
    required String itemDescription,
    http.Client? client,
  }) async {
    final prompt = buildAnalysisPrompt(
      projectName: projectName,
      checklistItem: checklistItem,
      itemDescription: itemDescription,
    );
    final apiKey = getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const GroqException(
        'Groq API key not configured. Please add GROQ_API_KEY to your .env file.',
        isMissingKey: true,
      );
    }

    final requestClient = client ?? http.Client();
    try {
      String lastError = '';
      for (final modelName in availableModels) {
        final payload = {
          'model': modelName,
          'messages': [
            {
              'role': 'system',
              'content': engineeringInstructionsFor(checklistItem),
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.4,
          'max_tokens': 4096,
        };

        final response = await requestClient
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final decoded =
              jsonDecode(utf8.decode(response.bodyBytes))
                  as Map<String, dynamic>;
          final choices = decoded['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              try {
                final report = EngineeringReport.fromResponse(
                  content,
                  requireTables: true,
                );
                return jsonEncode(report.toJson());
              } on FormatException {
                lastError =
                    'The AI returned an incomplete report. Please regenerate the analysis.';
              }
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
      if (client == null) requestClient.close();
    }
  }
}
