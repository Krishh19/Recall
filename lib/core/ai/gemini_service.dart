import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gemini_service.g.dart';

/// Structured response from Google Gemini AI.
class AISummaryResult {
  /// Creates an [AISummaryResult].
  const AISummaryResult({
    required this.summary,
    required this.keyPoints,
    required this.category,
    required this.tags,
    this.estimatedReadTimeMinutes = 2,
  });

  /// 1-2 sentence plain-language summary.
  final String summary;

  /// 3 bulleted key takeaways.
  final List<String> keyPoints;

  /// High-level category classification.
  final String category;

  /// 3-6 lowercase keywords.
  final List<String> tags;

  /// Estimated reading time in minutes.
  final int estimatedReadTimeMinutes;

  /// Whether the AI indicated that the provided content was unsummarizable.
  bool get isCannotSummarize => summary == 'CANNOT_SUMMARIZE';

  /// Deserializes from Gemini's JSON response.
  factory AISummaryResult.fromJson(Map<String, dynamic> json) {
    final rawKeyPoints = json['key_points'];
    final keyPoints =
        rawKeyPoints is List
            ? rawKeyPoints.map((e) => e.toString()).toList()
            : <String>[];

    final rawTags = json['tags'];
    final tags =
        rawTags is List
            ? rawTags.map((e) => e.toString().toLowerCase()).toList()
            : <String>[];

    return AISummaryResult(
      summary:
          json['summary'] as String? ??
          'Summary generated for saved bookmark.',
      keyPoints: keyPoints,
      category: json['category'] as String? ?? 'Other',
      tags: tags,
      estimatedReadTimeMinutes:
          json['estimated_read_time_minutes'] as int? ?? 2,
    );
  }
}

/// Service that interacts directly with the Google Gemini REST API.
class GeminiService {
  /// Creates a [GeminiService].
  GeminiService({
    FlutterSecureStorage? secureStorage,
    Dio? dio,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _dio = dio ?? Dio();

  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  static const String _envApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static const String _storageKey = 'gemini_api_key';

  static const String _systemPrompt = '''
You are the content intelligence engine for Recall, a reading and bookmarking app.
Analyze the provided content and return a JSON object adhering STRICTLY to this format:
{
  "summary": "1-2 plain-language sentences summarizing the substantive core idea of the content",
  "key_points": ["point 1", "point 2", "point 3"],
  "category": "one of: Technology, Business, Health, Education, Entertainment, News, Food, Finance, Other",
  "tags": ["3-6 lowercase keywords relating to the topic, not generic words like link/post/url"],
  "estimated_read_time_minutes": 2
}

CRITICAL ANTI-HALLUCINATION RULES:
- If the provided content only contains a URL, login notice, site navigation, or lacks the actual text/transcript of the post or article, return:
{
  "summary": "CANNOT_SUMMARIZE",
  "key_points": [],
  "category": "Other",
  "tags": [],
  "estimated_read_time_minutes": 1
}
- Do NOT describe the existence of the hyperlink itself or write generic sentences like "This entry refers to an Instagram post".
- Do NOT include markdown code fences or any text outside the JSON object.
''';

  /// Retrieves the active API key (from secure storage or environment variable).
  Future<String> getApiKey() async {
    final customKey = await _secureStorage.read(key: _storageKey);
    if (customKey != null && customKey.trim().isNotEmpty) {
      return customKey.trim();
    }
    if (_envApiKey.isNotEmpty) {
      return _envApiKey;
    }
    return '';
  }

  /// Checks if an API key has been configured.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key.isNotEmpty;
  }

  /// Updates or clears the user's custom API key in secure storage.
  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _secureStorage.delete(key: _storageKey);
    } else {
      await _secureStorage.write(key: _storageKey, value: trimmed);
    }
  }

  /// Returns a safe, masked representation of the active API key (e.g. `AIza••••••••••••`).
  /// Never exposes the full raw key.
  Future<String> getMaskedKey() async {
    final key = await getApiKey();
    if (key.isEmpty) return '';
    if (key.length <= 6) return '••••••';
    final prefix = key.substring(0, 4);
    return '$prefix••••••••••••';
  }

  /// Tests a candidate API key against the Gemini API without saving it.
  /// Throws user-friendly [GeminiValidationException] on failure.
  Future<void> validateApiKey(String candidateKey) async {
    final key = candidateKey.trim();
    if (key.isEmpty) {
      throw const GeminiValidationException(
        'Please enter a valid API key.',
        category: GeminiValidationCategory.invalidKey,
      );
    }

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$key';

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': 'ping'},
          ],
        },
      ],
      'generationConfig': {
        'maxOutputTokens': 1,
      },
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return;
      }

      if (response.statusCode == 429) {
        throw const GeminiValidationException(
          'Your key is valid, but Gemini isn\'t currently allowing this request. Check your Google AI Studio project, API access, or usage limits.',
          category: GeminiValidationCategory.quotaOrPermission,
        );
      } else if (response.statusCode == 403) {
        final data = response.data;
        String errorMsg = '';
        if (data != null) {
          final errorObj = data['error'];
          if (errorObj is Map) {
            errorMsg = errorObj['message']?.toString() ?? '';
          }
        }
        if (errorMsg.contains('PERMISSION_DENIED') ||
            errorMsg.contains('RESOURCE_EXHAUSTED') ||
            errorMsg.contains('quota') ||
            errorMsg.contains('billing')) {
          throw const GeminiValidationException(
            'Your key is valid, but Gemini isn\'t currently allowing this request. Check your Google AI Studio project, API access, or usage limits.',
            category: GeminiValidationCategory.quotaOrPermission,
          );
        }
        throw const GeminiValidationException(
          'We couldn\'t verify this API key. Check that you copied the complete key and try again.',
          category: GeminiValidationCategory.invalidKey,
        );
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        throw const GeminiValidationException(
          'We couldn\'t verify this API key. Check that you copied the complete key and try again.',
          category: GeminiValidationCategory.invalidKey,
        );
      } else {
        throw GeminiValidationException(
          'Gemini returned status ${response.statusCode}. Check the key and try again.',
          category: GeminiValidationCategory.invalidKey,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const GeminiValidationException(
          'Couldn\'t reach Gemini. Check your internet connection and try again.',
          category: GeminiValidationCategory.networkError,
        );
      }
      if (e.response?.statusCode == 429) {
        throw const GeminiValidationException(
          'Your key is valid, but Gemini isn\'t currently allowing this request. Check your Google AI Studio project, API access, or usage limits.',
          category: GeminiValidationCategory.quotaOrPermission,
        );
      }
      if (e.response?.statusCode == 400 ||
          e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        throw const GeminiValidationException(
          'We couldn\'t verify this API key. Check that you copied the complete key and try again.',
          category: GeminiValidationCategory.invalidKey,
        );
      }
      throw const GeminiValidationException(
        'Couldn\'t reach Gemini. Check your internet connection and try again.',
        category: GeminiValidationCategory.networkError,
      );
    } catch (e) {
      if (e is GeminiValidationException) rethrow;
      throw const GeminiValidationException(
        'Couldn\'t verify the API key. Please try again.',
        category: GeminiValidationCategory.invalidKey,
      );
    }
  }

  /// Calls Google Gemini (`gemini-2.5-flash`) to generate structured summaries and tags.
  Future<AISummaryResult> summarize({
    required String title,
    required String content,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey.isEmpty) {
      throw StateError(
        'Gemini API key is not configured. Please add your key in Settings or build with --dart-define=GEMINI_API_KEY=your_key',
      );
    }
    final trimmedContent =
        content.length > 6000 ? content.substring(0, 6000) : content;
    final promptText = 'Title: $title\n\nContent:\n$trimmedContent';

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      'contents': [
        {
          'parts': [
            {'text': promptText},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      },
    };

    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: payload,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data!;
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final contentObj = candidates.first['content'] as Map<String, dynamic>?;
        final parts = contentObj?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final rawJsonText = parts.first['text'] as String? ?? '{}';
          var cleanJson = rawJsonText.trim();
          if (cleanJson.startsWith('```json')) {
            cleanJson = cleanJson.substring(7);
          } else if (cleanJson.startsWith('```')) {
            cleanJson = cleanJson.substring(3);
          }
          if (cleanJson.endsWith('```')) {
            cleanJson = cleanJson.substring(0, cleanJson.length - 3);
          }
          cleanJson = cleanJson.trim();
          final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
          return AISummaryResult.fromJson(parsed);
        }
      }
    }

    throw Exception(
      'Gemini API returned invalid response (${response.statusCode})',
    );
  }
}

/// Categorized outcome for candidate Gemini API key verification.
enum GeminiValidationCategory {
  /// The key was rejected by Gemini (HTTP 400, 401, 403 invalid key).
  invalidKey,

  /// Network error or unreachable endpoint.
  networkError,

  /// Valid key format/project but quota exhausted or permissions restricted.
  quotaOrPermission,
}

/// Thrown when candidate Gemini API key validation fails.
class GeminiValidationException implements Exception {
  /// Creates a [GeminiValidationException].
  const GeminiValidationException(
    this.message, {
    this.category = GeminiValidationCategory.invalidKey,
  });

  /// User-friendly explanation.
  final String message;

  /// The root failure classification.
  final GeminiValidationCategory category;

  @override
  String toString() => message;
}

/// Provides the active [GeminiService] instance.
@Riverpod(keepAlive: true)
GeminiService geminiService(Ref ref) {
  return GeminiService();
}

/// Exposes whether a Gemini API key is currently configured.
@riverpod
Future<bool> isGeminiConfigured(Ref ref) async {
  final gemini = ref.watch(geminiServiceProvider);
  return gemini.hasApiKey();
}

/// Exposes the safe masked Gemini API key (e.g. AIza••••••••••••) if configured.
@riverpod
Future<String> maskedGeminiKey(Ref ref) async {
  final gemini = ref.watch(geminiServiceProvider);
  return gemini.getMaskedKey();
}
