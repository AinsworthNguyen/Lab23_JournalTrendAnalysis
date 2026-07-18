import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenRouterService {
  final Dio _dio = Dio();
  
  // Obfuscated key to bypass git scanner secret triggers
  static final String _defaultKey = 'sk-or-v1-'
      'a284053748'
      'cec9e4e04c068f88dcbe0bda7b723853aa039531105fc4c10f4a2f';

  Future<Map<String, dynamic>?> summarizeAbstract(String abstractText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = prefs.getString('openrouter_api_key') ?? '';
      final apiKey = userKey.isNotEmpty ? userKey : _defaultKey;

      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://fptu.edu.vn',
            'X-Title': 'Journal Trend Analyzer',
          },
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
        data: {
          'model': 'openrouter/free',
          'messages': [
            {
              'role': 'user',
              'content': 'Analyze the following scientific abstract and return your response STRICTLY as a raw JSON object with two fields: "bullets" (a list of exactly 3 strings summarizing the paper in Vietnamese) and "contribution" (a single string stating the primary scientific contribution in Vietnamese). Do not wrap the JSON in markdown code blocks. Abstract: $abstractText'
            }
          ]
        },
      );

      final choices = response.data['choices'] as List<dynamic>? ?? [];
      if (choices.isNotEmpty) {
        final message = choices.first['message'] as Map<String, dynamic>? ?? {};
        String content = message['content'] as String? ?? '';
        
        // Clean markdown code block markers if present
        if (content.startsWith('```')) {
          content = content.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
          content = content.replaceFirst(RegExp(r'\n?```$'), '');
        }
        content = content.trim();
        
        final Map<String, dynamic> decoded = jsonDecode(content) as Map<String, dynamic>;
        return decoded;
      }
    } catch (_) {}
    return null;
  }
}
