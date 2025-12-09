import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 관리 서비스
/// 마지막 단어 갱신 날짜 등의 앱 설정 저장
class PreferencesService {
  // 싱글톤 패턴
  static final PreferencesService instance = PreferencesService._init();
  PreferencesService._init();

  // SharedPreferences 인스턴스
  SharedPreferences? _prefs;

  // 키 상수
  static const String _lastWordUpdateDateKey = 'last_word_update_date';

  /// SharedPreferences 초기화
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 마지막 단어 갱신 날짜 저장
  /// date: 'yyyy-MM-dd' 형식의 날짜 문자열
  Future<bool> setLastWordUpdateDate(String date) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(_lastWordUpdateDateKey, date);
  }

  /// 마지막 단어 갱신 날짜 조회
  /// 반환값: 'yyyy-MM-dd' 형식의 날짜 문자열 또는 null (저장된 값이 없는 경우)
  String? getLastWordUpdateDate() {
    return _prefs?.getString(_lastWordUpdateDateKey);
  }

  /// 오늘 날짜 가져오기 (yyyy-MM-dd 형식)
  String getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 단어 갱신이 필요한지 확인
  /// 반환값: true (갱신 필요), false (갱신 불필요)
  bool shouldUpdateWords() {
    final lastUpdateDate = getLastWordUpdateDate();
    final today = getTodayDate();

    // 저장된 날짜가 없거나, 저장된 날짜가 오늘이 아니면 갱신 필요
    return lastUpdateDate == null || lastUpdateDate != today;
  }
}
