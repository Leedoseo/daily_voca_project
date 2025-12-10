import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// 로컬 알림 서비스
/// 일일 학습 리마인더를 관리합니다
class NotificationService {
  // 싱글톤 패턴
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 타임존 데이터 초기화
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      // Android 설정
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 설정
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings);
      _isInitialized = true;

      print('알림 서비스 초기화 완료');
    } catch (e) {
      print('알림 서비스 초기화 실패: $e');
    }
  }

  /// 권한 요청 (iOS)
  Future<bool?> requestPermissions() async {
    if (!_isInitialized) await initialize();

    return await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// 일일 학습 알림 예약 (매일 특정 시간에)
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _notifications.zonedSchedule(
        0, // 알림 ID
        '오늘의 영단어 학습 시간입니다! 📚',
        '새로운 단어들이 기다리고 있어요. 지금 바로 학습을 시작해보세요!',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            '일일 학습 알림',
            channelDescription: '매일 정해진 시간에 학습을 알려드립니다',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
      );

      print('일일 알림 설정 완료: $hour:$minute');
    } catch (e) {
      print('알림 예약 실패: $e');
    }
  }

  /// 다음 알림 시간 계산
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 이미 오늘의 알림 시간이 지났다면 내일로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 즉시 알림 표시 (테스트용)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _notifications.show(
        1, // 알림 ID
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'immediate_notification',
            '즉시 알림',
            channelDescription: '즉시 표시되는 알림',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      print('즉시 알림 표시 완료');
    } catch (e) {
      print('즉시 알림 표시 실패: $e');
    }
  }

  /// 모든 예약된 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('모든 알림 취소 완료');
  }

  /// 특정 알림 취소
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('알림 ID $id 취소 완료');
  }
}
