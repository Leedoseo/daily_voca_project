import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word.dart';

/// 단어 API 서비스
/// 무료 API를 사용하여 랜덤 영단어를 가져옴
class WordApiService {
  // 싱글톤 패턴
  static final WordApiService instance = WordApiService._init();
  WordApiService._init();

  // Random Word API (무료, 등록 불필요)
  static const String _randomWordApiUrl =
      'https://random-word-api.herokuapp.com/word';

  // Free Dictionary API (단어 정의 조회용)
  static const String _dictionaryApiUrl =
      'https://api.dictionaryapi.dev/api/v2/entries/en';

  /// 랜덤 단어 가져오기
  /// count: 가져올 단어 개수 (기본값: 50)
  /// onProgress: 진행률 콜백 함수 (로딩 화면에서 사용)
  Future<List<Word>> fetchRandomWords({
    int count = 50,
    Function(int loaded, int total)? onProgress,
  }) async {
    try {
      // 1. 랜덤 단어 목록 가져오기 (50개)
      final wordListResponse =
          await http.get(Uri.parse('$_randomWordApiUrl?number=$count'));

      if (wordListResponse.statusCode != 200) {
        throw Exception('단어 목록을 가져오는데 실패했습니다');
      }

      final List<dynamic> wordList = json.decode(wordListResponse.body);
      final List<Word> words = [];

      // 2. 각 단어의 정의를 가져오기
      for (int i = 0; i < wordList.length && i < count; i++) {
        final String wordText = wordList[i];

        try {
          // 딕셔너리 API에서 단어 정의 가져오기
          final definitionResponse =
              await http.get(Uri.parse('$_dictionaryApiUrl/$wordText'));

          if (definitionResponse.statusCode == 200) {
            final List<dynamic> definitions =
                json.decode(definitionResponse.body);

            if (definitions.isNotEmpty) {
              final meanings = definitions[0]['meanings'] as List<dynamic>;

              if (meanings.isNotEmpty) {
                final firstMeaning = meanings[0];
                final definitions =
                    firstMeaning['definitions'] as List<dynamic>;

                if (definitions.isNotEmpty) {
                  final definition = definitions[0]['definition'] as String;
                  final example = definitions[0]['example'] as String? ??
                      'No example available.';

                  words.add(Word(
                    word: wordText,
                    meaning: definition,
                    example: example,
                  ));
                }
              }
            }
          } else {
            // API에서 정의를 찾지 못한 경우 기본값 사용
            words.add(Word(
              word: wordText,
              meaning: 'Definition not available',
              example: 'Example not available',
            ));
          }
        } catch (e) {
          // 개별 단어 조회 실패 시 기본값 사용
          words.add(Word(
            word: wordText,
            meaning: 'Definition not available',
            example: 'Example not available',
          ));
        }

        // 진행률 콜백 호출 (로딩 화면 업데이트)
        if (onProgress != null) {
          onProgress(i + 1, count);
        }

        // API 속도 제한 방지를 위한 짧은 딜레이
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return words;
    } catch (e) {
      // API 호출 실패 시 폴백 단어 리스트 반환
      return _getFallbackWords();
    }
  }

  /// API 실패 시 사용할 기본 단어 리스트
  List<Word> _getFallbackWords() {
    return [
      Word(
          word: 'accomplish',
          meaning: 'to succeed in doing something',
          example: 'She accomplished her goal of running a marathon.'),
      Word(
          word: 'achieve',
          meaning: 'to successfully reach a goal',
          example: 'He achieved great success in his career.'),
      Word(
          word: 'acquire',
          meaning: 'to gain or obtain something',
          example: 'She acquired new skills through practice.'),
      Word(
          word: 'adapt',
          meaning: 'to change to fit new conditions',
          example: 'Animals adapt to their environment.'),
      Word(
          word: 'analyze',
          meaning: 'to examine something carefully',
          example: 'Scientists analyze data to find patterns.'),
      Word(
          word: 'approach',
          meaning: 'to come near or closer to something',
          example: 'The deadline is approaching quickly.'),
      Word(
          word: 'benefit',
          meaning: 'an advantage or profit',
          example: 'Exercise has many health benefits.'),
      Word(
          word: 'challenge',
          meaning: 'a difficult task or problem',
          example: 'Learning a new language is a challenge.'),
      Word(
          word: 'communicate',
          meaning: 'to share information with others',
          example: 'It\'s important to communicate clearly.'),
      Word(
          word: 'conclude',
          meaning: 'to come to an end or decision',
          example: 'The meeting will conclude at 5 PM.'),
    ];
  }
}
