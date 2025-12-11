import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../services/database_service.dart';
import '../services/word_api_service.dart';
import '../services/preferences_service.dart';

/// 단어 데이터 관리 Provider
/// 단어 로딩, 갱신, 상태 관리를 담당
class WordProvider with ChangeNotifier {
  // 서비스 인스턴스
  final DatabaseService _dbService = DatabaseService.instance;
  final WordApiService _apiService = WordApiService.instance;
  final PreferencesService _prefsService = PreferencesService.instance;

  // 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 진행률
  double _progress = 0.0;
  double get progress => _progress;

  // 로딩된 단어 수
  int _loadedCount = 0;
  int get loadedCount => _loadedCount;

  // 전체 단어 수
  final int _totalCount = 50;
  int get totalCount => _totalCount;

  // 로딩 메시지
  String _message = '단어 데이터 확인 중...';
  String get message => _message;

  // 에러 상태
  bool _hasError = false;
  bool get hasError => _hasError;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // 단어 목록 (필요한 경우)
  List<Word> _words = [];
  List<Word> get words => _words;

  /// 단어 데이터 초기화 및 로딩
  Future<void> loadWords() async {
    _isLoading = true;
    _hasError = false;
    _progress = 0.0;
    _loadedCount = 0;
    _message = '단어 데이터 확인 중...';
    notifyListeners();

    try {
      // SharedPreferences 초기화
      await _prefsService.init();

      // 단어 갱신이 필요한지 확인
      if (_prefsService.shouldUpdateWords()) {
        _message = '새로운 단어를 가져오는 중...';
        notifyListeners();

        // 기존 단어 삭제
        await _dbService.deleteAllWords();

        // API에서 단어 가져오기 (진행률 콜백 포함)
        final words = await _apiService.fetchRandomWords(
          count: _totalCount,
          onProgress: (loaded, total) {
            // 진행률 업데이트
            _loadedCount = loaded;
            _progress = loaded / total;
            _message = '단어 로딩 중... $loaded/$total';
            notifyListeners();
          },
        );

        // 데이터베이스에 삽입
        _message = '단어를 저장하는 중...';
        notifyListeners();
        await _dbService.initializeWithWords(words);

        // 마지막 갱신 날짜 저장
        await _prefsService.setLastWordUpdateDate(_prefsService.getTodayDate());

        _words = words;
        _message = '완료!';
        _progress = 1.0;
        notifyListeners();
      } else {
        // 단어 갱신이 필요 없으면 바로 완료
        _message = '단어 데이터 로드 완료!';
        _progress = 1.0;
        notifyListeners();
      }

      // 잠시 대기
      await Future.delayed(const Duration(milliseconds: 500));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // 에러 발생 시
      _hasError = true;
      _errorMessage = '단어를 불러오는 중 오류가 발생했습니다.\n임시 단어로 학습을 시작합니다.';
      _message = '오류 발생';
      notifyListeners();

      // 3초 대기
      await Future.delayed(const Duration(seconds: 3));

      _isLoading = false;
      notifyListeners();
    }
  }

  /// 데이터베이스에서 모든 단어 가져오기
  Future<void> fetchWordsFromDatabase() async {
    try {
      _words = await _dbService.getAllWords();
      notifyListeners();
    } catch (e) {
      _hasError = true;
      _errorMessage = '단어를 불러오는데 실패했습니다: $e';
      notifyListeners();
    }
  }

  /// 단어 갱신 필요 여부 확인
  bool shouldUpdateWords() {
    return _prefsService.shouldUpdateWords();
  }

  /// 에러 초기화
  void clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  // ============ CRUD 메서드 ============

  /// 단어 개수 조회
  Future<int> getWordCount() async {
    try {
      return await _dbService.getWordCount();
    } catch (e) {
      return 0;
    }
  }

  /// ID로 단어 조회
  Future<Word?> getWordById(int id) async {
    try {
      return await _dbService.getWord(id);
    } catch (e) {
      return null;
    }
  }

  /// 단어 추가
  Future<bool> addWord(Word word) async {
    try {
      await _dbService.insertWord(word);
      await fetchWordsFromDatabase(); // 목록 갱신
      notifyListeners();
      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = '단어 추가에 실패했습니다: $e';
      notifyListeners();
      return false;
    }
  }

  /// 단어 수정
  Future<bool> updateWord(Word word) async {
    try {
      await _dbService.updateWord(word);
      await fetchWordsFromDatabase(); // 목록 갱신
      notifyListeners();
      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = '단어 수정에 실패했습니다: $e';
      notifyListeners();
      return false;
    }
  }

  /// 단어 삭제
  Future<bool> deleteWord(int id) async {
    try {
      await _dbService.deleteWord(id);
      await fetchWordsFromDatabase(); // 목록 갱신
      notifyListeners();
      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = '단어 삭제에 실패했습니다: $e';
      notifyListeners();
      return false;
    }
  }

  /// 단어 검색 (로컬에서 필터링)
  Future<List<Word>> searchWords(String query) async {
    try {
      final allWords = await _dbService.getAllWords();
      if (query.isEmpty) return allWords;

      return allWords.where((word) {
        return word.word.toLowerCase().contains(query.toLowerCase()) ||
               word.meaning.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// 틀린 단어 목록 조회
  Future<List<Word>> getIncorrectWords() async {
    try {
      return await _dbService.getIncorrectWords();
    } catch (e) {
      return [];
    }
  }

  /// 틀린 단어 개수 조회
  Future<int> getIncorrectWordsCount() async {
    try {
      return await _dbService.getIncorrectWordsCount();
    } catch (e) {
      return 0;
    }
  }
}
