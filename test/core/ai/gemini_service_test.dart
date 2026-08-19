import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/ai/gemini_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late GeminiService service;
  String? capturedUrl;
  dynamic capturedData;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    dio = Dio();
    capturedUrl = null;
    capturedData = null;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedUrl = options.uri.toString();
          capturedData = options.data;

          if (options.uri.path.contains('generateContent')) {
            final dummyResponse = {
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'summary': 'A valid summary for the article.',
                          'key_points': ['Point 1', 'Point 2', 'Point 3'],
                          'category': 'Technology',
                          'tags': ['flutter', 'gemini', 'dart'],
                          'estimated_read_time_minutes': 3,
                        }),
                      },
                    ],
                  },
                },
              ],
            };
            return handler.resolve(
              Response(
                requestOptions: options,
                data: dummyResponse,
                statusCode: 200,
              ),
            );
          }
          return handler.next(options);
        },
      ),
    );

    service = GeminiService(
      secureStorage: const FlutterSecureStorage(),
      dio: dio,
    );
  });

  group('Gemini 3.6 Flash Endpoint & Compatibility Tests', () {
    test('validateApiKey targets gemini-3.6-flash endpoint', () async {
      await service.validateApiKey('AIzaSyCandidateKey123');

      expect(capturedUrl, contains('models/gemini-3.6-flash:generateContent'));
      expect(capturedUrl, contains('key=AIzaSyCandidateKey123'));
      expect(capturedData, isA<Map<String, dynamic>>());
      final payload = capturedData as Map<String, dynamic>;
      final config = payload['generationConfig'] as Map<String, dynamic>?;
      expect(config?['maxOutputTokens'], equals(1));
    });

    test('summarize targets gemini-3.6-flash endpoint without deprecated sampling parameters', () async {
      await service.setApiKey('AIzaSySecretKey456');

      final result = await service.summarize(
        title: 'Gemini 3.6 Flash in Recall',
        content: 'Recall now supports Gemini 3.6 Flash natively for AI summarization.',
      );

      expect(capturedUrl, contains('models/gemini-3.6-flash:generateContent'));
      expect(capturedUrl, contains('key=AIzaSySecretKey456'));
      expect(capturedData, isA<Map<String, dynamic>>());

      final payload = capturedData as Map<String, dynamic>;
      final config = payload['generationConfig'] as Map<String, dynamic>?;

      // Must have JSON mode
      expect(config?['responseMimeType'], equals('application/json'));

      // Must NOT have deprecated sampling or removed candidate parameters
      expect(config?.containsKey('temperature'), isFalse);
      expect(config?.containsKey('top_p'), isFalse);
      expect(config?.containsKey('top_k'), isFalse);
      expect(config?.containsKey('topP'), isFalse);
      expect(config?.containsKey('topK'), isFalse);
      expect(config?.containsKey('candidate_count'), isFalse);
      expect(config?.containsKey('candidateCount'), isFalse);

      // Result is parsed properly
      expect(result.summary, 'A valid summary for the article.');
      expect(result.keyPoints, ['Point 1', 'Point 2', 'Point 3']);
      expect(result.category, 'Technology');
      expect(result.tags, ['flutter', 'gemini', 'dart']);
      expect(result.estimatedReadTimeMinutes, 3);
    });

    test('summarize handles markdown-fenced JSON responses', () async {
      dio.interceptors.clear();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final fencedResponse = {
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': '```json\n{\n  "summary": "Fenced summary.",\n  "key_points": ["Point 1"],\n  "category": "News",\n  "tags": ["news"]\n}\n```',
                      },
                    ],
                  },
                },
              ],
            };
            return handler.resolve(
              Response(
                requestOptions: options,
                data: fencedResponse,
                statusCode: 200,
              ),
            );
          },
        ),
      );

      await service.setApiKey('test-key');
      final result = await service.summarize(
        title: 'Title',
        content: 'Content',
      );

      expect(result.summary, 'Fenced summary.');
      expect(result.category, 'News');
    });
  });
}
