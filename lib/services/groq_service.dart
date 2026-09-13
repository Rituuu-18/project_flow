import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroqException implements Exception {
  final String message;
  final bool isMissingKey;

  const GroqException(this.message, {this.isMissingKey = false});

  @override
  String toString() => message;
}

class GroqService {
  static const String _prefsKey = 'custom_groq_api_key';
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const List<String> availableModels = [
    'openai/gpt-oss-120b',
    'qwen/qwen3.8-27b',
    'groq/compound',
    'llama-3.3-70b-versatile',
  ];
  static const String defaultModel = 'openai/gpt-oss-120b';


  /// Resolves the Groq API key safely from:
  /// 1. Locally saved in SharedPreferences (user override/APK fallback)
  /// 2. .env file (GROQ_API_KEY)
  /// 3. Compile-time --dart-define=GROQ_API_KEY=...
  static Future<String?> getApiKey() async {
    // 1. SharedPreferences override
    try {
      final prefs = await SharedPreferences.getInstance();
      final localKey = prefs.getString(_prefsKey)?.trim();
      if (localKey != null && localKey.isNotEmpty) {
        return localKey;
      }
    } catch (_) {}

    // 2. dotenv
    try {
      final envKey = dotenv.env['GROQ_API_KEY']?.trim();
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    } catch (_) {}

    // 3. dart-define compile-time environment variable
    const defineKey = String.fromEnvironment('GROQ_API_KEY');
    if (defineKey.trim().isNotEmpty) {
      return defineKey.trim();
    }

    return null;
  }

  /// Checks if any valid API key is currently accessible.
  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Saves a custom API key to SharedPreferences (e.g. from in-app dialog in APK).
  static Future<void> setCustomApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, trimmed);
    }
  }

  /// Removes any custom API key saved in SharedPreferences.
  static Future<void> clearCustomApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
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
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const GroqException(
        'Groq API key not found. Please provide your API key in .env or via settings.',
        isMissingKey: true,
      );
    }

    final promptBuffer = StringBuffer();
    promptBuffer.writeln('Analyze the following engineering review checklist item for our product project:');
    promptBuffer.writeln('• Project Name: $projectName');
    promptBuffer.writeln('• Review Stage: $stageName');
    if (stageDescription != null && stageDescription.isNotEmpty) {
      promptBuffer.writeln('• Stage Objective: $stageDescription');
    }
    promptBuffer.writeln('• Checklist Item / Sub-step: $checklistItem');
    if (itemDescription.isNotEmpty) {
      promptBuffer.writeln('• Item Description: $itemDescription');
    }
    if (discipline.isNotEmpty) {
      promptBuffer.writeln('• Lead Discipline: $discipline');
    }
    if (existingNotes != null && existingNotes.trim().isNotEmpty) {
      promptBuffer.writeln('• Current Team Notes: ${existingNotes.trim()}');
    }

    promptBuffer.writeln();
    promptBuffer.writeln(
      'Please generate a concise, rigorous engineering review analysis formatted clearly with the following sections:\n'
      '1. KEY VERIFICATION CHECKS (Must-verify acceptance criteria & technical checks)\n'
      '2. RISK & FAILURE MODES (Critical edge cases, potential failure modes, or common pitfalls)\n'
      '3. RECOMMENDED EVIDENCE & ARTIFACTS (Specific test reports, calculations, CAD/simulation data to attach)\n'
      '4. RECOMMENDED NEXT ACTIONS (Immediate tactical steps to close this item)\n\n'
      'Keep it structured, engineering-focused, bullet-pointed, and ready to be directly saved as review notes.',
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
                  'Provide concise, high-density, professional technical review notes. Avoid marketing fluff or generic platitudes.',
            },
            {
              'role': 'user',
              'content': promptBuffer.toString(),
            },
          ],
          'temperature': 0.25,
          'max_tokens': 1500,
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
            'Invalid Groq API key (401 Unauthorized). Please verify your key.',
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
              continue;
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
