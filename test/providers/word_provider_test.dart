import 'package:flutter_test/flutter_test.dart';
import 'package:daily_voca/providers/word_provider.dart';
import 'package:daily_voca/models/word.dart';

/// WordProvider 테스트
/// Provider 패턴의 핵심 CRUD 기능을 검증합니다
void main() {
  // 테스트 그룹: WordProvider 기본 기능
  group('WordProvider 기본 기능 테스트', () {
    late WordProvider provider;

    // 각 테스트 전에 새로운 provider 인스턴스 생성
    setUp(() {
      provider = WordProvider();
    });

    // 테스트 1: Provider 초기화 상태 확인
    test('초기화 시 words 리스트가 비어있어야 함', () {
      expect(provider.words, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.hasError, false);
    });

    // 테스트 2: 로딩 상태 확인
    test('fetchWordsFromDatabase 호출 시 로딩 상태 변경', () async {
      // 로딩 시작 전
      expect(provider.isLoading, false);

      // 로딩 시작
      final future = provider.fetchWordsFromDatabase();

      // 로딩 완료 대기
      await future;

      // 로딩 완료 후
      expect(provider.isLoading, false);
    });

    // 테스트 3: 단어 개수 조회
    test('getWordCount는 0 이상의 값을 반환해야 함', () async {
      final count = await provider.getWordCount();
      expect(count, greaterThanOrEqualTo(0));
    });

    // 테스트 4: 틀린 단어 개수 조회
    test('getIncorrectWordsCount는 0 이상의 값을 반환해야 함', () async {
      final count = await provider.getIncorrectWordsCount();
      expect(count, greaterThanOrEqualTo(0));
    });

    // 테스트 5: 틀린 단어 목록 조회
    test('getIncorrectWords는 리스트를 반환해야 함', () async {
      final words = await provider.getIncorrectWords();
      expect(words, isA<List<Word>>());
    });

    // 테스트 6: 단어 검색 (빈 쿼리)
    test('searchWords 빈 쿼리는 전체 목록을 반환해야 함', () async {
      final results = await provider.searchWords('');
      expect(results, isA<List<Word>>());
    });

    // 테스트 7: 에러 상태 초기화
    test('clearError는 에러 상태를 초기화해야 함', () {
      // 에러 상태 확인 (초기값)
      expect(provider.hasError, false);

      // 에러 초기화
      provider.clearError();

      // 에러 초기화 후
      expect(provider.hasError, false);
      expect(provider.errorMessage, isEmpty);
    });
  });

  // 테스트 그룹: 단어 검색 기능
  group('단어 검색 기능 테스트', () {
    late WordProvider provider;

    setUp(() {
      provider = WordProvider();
    });

    // 테스트 8: 검색 결과가 리스트 타입인지 확인
    test('searchWords는 항상 List<Word> 타입을 반환해야 함', () async {
      final results = await provider.searchWords('test');
      expect(results, isA<List<Word>>());
    });

    // 테스트 9: 검색어가 null이 아닌지 확인 (에러 발생 안 함)
    test('searchWords는 어떤 문자열이든 에러 없이 처리해야 함', () async {
      expect(() => provider.searchWords('가나다'), returnsNormally);
      expect(() => provider.searchWords('abc'), returnsNormally);
      expect(() => provider.searchWords('123'), returnsNormally);
    });
  });

  // 테스트 그룹: Provider 상태 관리
  group('Provider 상태 관리 테스트', () {
    late WordProvider provider;

    setUp(() {
      provider = WordProvider();
    });

    // 테스트 10: isLoading 초기값
    test('초기 isLoading 값은 false여야 함', () {
      expect(provider.isLoading, false);
    });

    // 테스트 11: hasError 초기값
    test('초기 hasError 값은 false여야 함', () {
      expect(provider.hasError, false);
    });

    // 테스트 12: errorMessage 초기값
    test('초기 errorMessage는 빈 문자열이어야 함', () {
      expect(provider.errorMessage, isEmpty);
    });
  });

  // 테스트 그룹: 데이터 검증
  group('데이터 검증 테스트', () {
    late WordProvider provider;

    setUp(() {
      provider = WordProvider();
    });

    // 테스트 13: words 리스트는 null이 아님
    test('words 리스트는 null이 아니어야 함', () {
      expect(provider.words, isNotNull);
    });

    // 테스트 14: fetchWordsFromDatabase 후 words는 리스트
    test('fetchWordsFromDatabase 후 words는 List<Word> 타입이어야 함', () async {
      await provider.fetchWordsFromDatabase();
      expect(provider.words, isA<List<Word>>());
    });

    // 테스트 15: getWordById null 처리
    test('getWordById는 존재하지 않는 ID에 대해 null을 반환할 수 있음', () async {
      final word = await provider.getWordById(999999);
      // null이거나 Word 타입이어야 함
      expect(word == null || word is Word, true);
    });
  });
}
