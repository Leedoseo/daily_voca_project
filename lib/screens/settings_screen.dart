import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// 설정 화면
/// 알림 설정 등을 관리합니다
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService.instance;

  // 알림 설정 상태
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 저장된 설정 로드
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? false;
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;

      setState(() {
        _notificationsEnabled = enabled;
        _notificationTime = TimeOfDay(hour: hour, minute: minute);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// 알림 설정 저장
  Future<void> _saveNotificationSettings({
    required bool enabled,
    TimeOfDay? time,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('notifications_enabled', enabled);

      if (time != null) {
        await prefs.setInt('notification_hour', time.hour);
        await prefs.setInt('notification_minute', time.minute);
      }

      if (enabled) {
        final timeToUse = time ?? _notificationTime;
        await _notificationService.scheduleDailyReminder(
          hour: timeToUse.hour,
          minute: timeToUse.minute,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '매일 ${timeToUse.hour}:${timeToUse.minute.toString().padLeft(2, '0')}에 알림을 받습니다',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _notificationService.cancelAllNotifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알림이 비활성화되었습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 알림 시간 선택
  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });

      if (_notificationsEnabled) {
        await _saveNotificationSettings(
          enabled: true,
          time: picked,
        );
      }
    }
  }

  /// 알림 테스트
  Future<void> _testNotification() async {
    await _notificationService.showImmediateNotification(
      title: '테스트 알림입니다! 📚',
      body: '알림이 정상적으로 작동하고 있습니다.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('테스트 알림을 전송했습니다'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 알림 설정 섹션
          Text(
            '알림',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // 알림 활성화/비활성화
          Card(
            child: SwitchListTile(
              title: const Text('일일 학습 알림'),
              subtitle: const Text('매일 정해진 시간에 학습을 알려드립니다'),
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });

                await _saveNotificationSettings(enabled: value);
              },
              secondary: const Icon(Icons.notifications_active),
            ),
          ),

          const SizedBox(height: 12),

          // 알림 시간 설정
          Card(
            child: ListTile(
              title: const Text('알림 시간'),
              subtitle: Text(
                '${_notificationTime.hour}:${_notificationTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16),
              ),
              leading: const Icon(Icons.access_time),
              trailing: const Icon(Icons.chevron_right),
              enabled: _notificationsEnabled,
              onTap: _notificationsEnabled ? _pickNotificationTime : null,
            ),
          ),

          const SizedBox(height: 12),

          // 알림 테스트 버튼
          Card(
            child: ListTile(
              title: const Text('알림 테스트'),
              subtitle: const Text('지금 바로 테스트 알림을 받아보세요'),
              leading: const Icon(Icons.notification_add),
              trailing: const Icon(Icons.send),
              onTap: _testNotification,
            ),
          ),

          const SizedBox(height: 32),

          // 앱 정보 섹션
          Text(
            '정보',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('버전'),
                  subtitle: const Text('1.0.0'),
                  leading: const Icon(Icons.info_outline),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('개발자'),
                  subtitle: const Text('Daily Voca Team'),
                  leading: const Icon(Icons.code),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
