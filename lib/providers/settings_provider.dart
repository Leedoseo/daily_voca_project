import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설정 관리 Provider
/// 일일 학습 목표, 알림 설정 등을 관리
class SettingsProvider with ChangeNotifier {
  // 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 일일 학습 목표
  int _dailyGoal = 50;
  int get dailyGoal => _dailyGoal;

  // 알림 설정
  bool _notificationsEnabled = false;
  bool get notificationsEnabled => _notificationsEnabled;

  int _notificationHour = 9;
  int get notificationHour => _notificationHour;

  int _notificationMinute = 0;
  int get notificationMinute => _notificationMinute;

  /// 설정 로드
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      _dailyGoal = prefs.getInt('daily_goal') ?? 50;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _notificationHour = prefs.getInt('notification_hour') ?? 9;
      _notificationMinute = prefs.getInt('notification_minute') ?? 0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 일일 학습 목표 설정
  Future<void> setDailyGoal(int goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_goal', goal);

      _dailyGoal = goal;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// 알림 활성화/비활성화
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);

      _notificationsEnabled = enabled;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// 알림 시간 설정
  Future<void> setNotificationTime(int hour, int minute) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', hour);
      await prefs.setInt('notification_minute', minute);

      _notificationHour = hour;
      _notificationMinute = minute;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// 설정 초기화
  Future<void> resetSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_goal', 50);
      await prefs.setBool('notifications_enabled', false);
      await prefs.setInt('notification_hour', 9);
      await prefs.setInt('notification_minute', 0);

      _dailyGoal = 50;
      _notificationsEnabled = false;
      _notificationHour = 9;
      _notificationMinute = 0;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
