import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

/// 통계 데이터 관리 Provider
/// 학습 통계 조회 및 관리를 담당
class StatisticsProvider with ChangeNotifier {
  // DB 서비스 인스턴스
  final DatabaseService _dbService = DatabaseService.instance;

  // 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 오늘 통계 데이터
  int _totalStudied = 0;
  int get totalStudied => _totalStudied;

  int _correctCount = 0;
  int get correctCount => _correctCount;

  int _incorrectCount = 0;
  int get incorrectCount => _incorrectCount;

  double _accuracy = 0.0;
  double get accuracy => _accuracy;

  // 주간/월간 통계 데이터
  List<Map<String, dynamic>> _weeklyStats = [];
  List<Map<String, dynamic>> get weeklyStats => _weeklyStats;

  List<Map<String, dynamic>> _monthlyStats = [];
  List<Map<String, dynamic>> get monthlyStats => _monthlyStats;

  // 단어별 통계
  List<Map<String, dynamic>> _mostIncorrectWords = [];
  List<Map<String, dynamic>> get mostIncorrectWords => _mostIncorrectWords;

  List<Map<String, dynamic>> _mostCorrectWords = [];
  List<Map<String, dynamic>> get mostCorrectWords => _mostCorrectWords;

  /// 통계 데이터 로드
  Future<void> loadStatistics() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 오늘 날짜
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 오늘의 학습 통계 조회
      final todayStats = await _dbService.getStudyStatisticsByDate(today);

      // 주간 통계 (최근 7일)
      final weeklyStats = await _dbService.getRecentDaysStatistics(7);

      // 월간 통계 (최근 30일)
      final monthlyStats = await _dbService.getRecentDaysStatistics(30);

      // 단어별 통계
      final mostIncorrectWords = await _dbService.getMostIncorrectWords(5);
      final mostCorrectWords = await _dbService.getMostCorrectWords(5);

      // 통계 계산
      final totalStudied = todayStats['totalStudied'] ?? 0;
      final correctCount = todayStats['correctCount'] ?? 0;
      final incorrectCount = todayStats['incorrectCount'] ?? 0;
      final accuracy = totalStudied > 0
          ? (correctCount / totalStudied * 100)
          : 0.0;

      _totalStudied = totalStudied;
      _correctCount = correctCount;
      _incorrectCount = incorrectCount;
      _accuracy = accuracy;
      _weeklyStats = weeklyStats;
      _monthlyStats = monthlyStats;
      _mostIncorrectWords = mostIncorrectWords;
      _mostCorrectWords = mostCorrectWords;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // 에러 발생 시 기본값으로 설정
      _totalStudied = 0;
      _correctCount = 0;
      _incorrectCount = 0;
      _accuracy = 0.0;
      _weeklyStats = [];
      _monthlyStats = [];
      _mostIncorrectWords = [];
      _mostCorrectWords = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 특정 날짜의 통계 조회
  Future<Map<String, dynamic>> getStatisticsByDate(String date) async {
    try {
      return await _dbService.getStudyStatisticsByDate(date);
    } catch (e) {
      return {
        'totalStudied': 0,
        'correctCount': 0,
        'incorrectCount': 0,
      };
    }
  }

  /// 통계 새로고침
  Future<void> refreshStatistics() async {
    await loadStatistics();
  }

  /// 통계 초기화 (테스트용)
  void clearStatistics() {
    _totalStudied = 0;
    _correctCount = 0;
    _incorrectCount = 0;
    _accuracy = 0.0;
    _weeklyStats = [];
    _monthlyStats = [];
    _mostIncorrectWords = [];
    _mostCorrectWords = [];
    notifyListeners();
  }
}
