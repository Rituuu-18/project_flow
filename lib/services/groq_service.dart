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
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
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
    String? projectOwner,
    String? projectStatus,
    required String stageName,
    String? stageDescription,
    String? subStepName,
    required String checklistItem,
    required String itemDescription,
    required String discipline,
    String? priority,
    String? assignee,
    String? problemStatement,
    List<String>? scopeIn,
    List<String>? scopeOut,
    String? engineeringComments,
    String? actionDescription,
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
    promptBuffer.writeln('Review the following engineering sub-step within its specific project context:');
    promptBuffer.writeln('• Project: $projectName');
    if (projectOwner != null && projectOwner.trim().isNotEmpty) {
      promptBuffer.writeln('• Project Lead: ${projectOwner.trim()}');
    }
    if (projectStatus != null && projectStatus.trim().isNotEmpty) {
      promptBuffer.writeln('• Project Status: ${projectStatus.trim()}');
    }
    promptBuffer.writeln('• Stage: $stageName');
    if (stageDescription != null && stageDescription.trim().isNotEmpty) {
      promptBuffer.writeln('• Stage Objective: ${stageDescription.trim()}');
    }
    if (subStepName != null &&
        subStepName.trim().isNotEmpty &&
        subStepName.trim() != checklistItem.trim()) {
      promptBuffer.writeln('• Sub-Step: ${subStepName.trim()}');
    }
    promptBuffer.writeln('• Checklist Item: $checklistItem');
    if (itemDescription.trim().isNotEmpty) {
      promptBuffer.writeln('• Item Scope: ${itemDescription.trim()}');
    }
    if (discipline.trim().isNotEmpty) {
      promptBuffer.writeln('• Lead Discipline: ${discipline.trim()}');
    }
    if (priority != null && priority.trim().isNotEmpty) {
      promptBuffer.writeln('• Priority: ${priority.trim()}');
    }
    if (assignee != null && assignee.trim().isNotEmpty) {
      promptBuffer.writeln('• Assignee: ${assignee.trim()}');
    }
    if (problemStatement != null && problemStatement.trim().isNotEmpty) {
      promptBuffer.writeln('• Problem Statement: ${problemStatement.trim()}');
    }
    if (scopeIn != null && scopeIn.isNotEmpty) {
      final inList = scopeIn.where((s) => s.trim().isNotEmpty).join(', ');
      if (inList.isNotEmpty) {
        promptBuffer.writeln('• Scope (In): $inList');
      }
    }
    if (scopeOut != null && scopeOut.isNotEmpty) {
      final outList = scopeOut.where((s) => s.trim().isNotEmpty).join(', ');
      if (outList.isNotEmpty) {
        promptBuffer.writeln('• Scope (Out): $outList');
      }
    }
    if (engineeringComments != null && engineeringComments.trim().isNotEmpty) {
      promptBuffer.writeln('• Engineering Comments: ${engineeringComments.trim()}');
    }
    if (actionDescription != null && actionDescription.trim().isNotEmpty) {
      promptBuffer.writeln('• Action Plan: ${actionDescription.trim()}');
    }
    if (existingNotes != null && existingNotes.trim().isNotEmpty) {
      promptBuffer.writeln('• Existing Team Notes: ${existingNotes.trim()}');
    }

    promptBuffer.writeln();
    promptBuffer.writeln(
      'CRITICAL INSTRUCTIONS (PROBLEM STATEMENT ONLY):\n'
      '- Focus exclusively on formulating the problem statement for this engineering item.\n'
      '- Do NOT output checks, risks, next actions, bullet lists, pleasantries, preambles, or markdown tables.\n'
      '- Structure your response under these exact 2 formal sections:\n\n'
      '### Engineering-focused version\n'
      '[1 formal, concise engineering objective statement (1-2 sentences): "Design a [system/component] that [quantifiable functional criteria] while [load, durability, or environmental constraints] in compliance with [applicable standards e.g. ANSI, ISO, OSHA] within [weight, geometry, or cost limits]."]\n\n'
      '### General problem statement\n'
      '[1 formal, clear paragraph (2-3 sentences): Identify the target user, their core operational need, why existing methods or products are deficient or hazardous, and the operational/environmental constraints that must be met.]\n',
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
                  'You are a senior engineering design review specialist. '
                  'Generate formal, simple, well-structured engineering problem statements (Engineering-focused version and General problem statement) tailored strictly to the provided project and sub-step context. '
                  'Do NOT output checks, risks, actions, or filler.',
            },
            {
              'role': 'user',
              'content': promptBuffer.toString(),
            },
          ],
          'temperature': 0.2,
          'max_tokens': 400,
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
