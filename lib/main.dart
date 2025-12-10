// Flutter의 핵심 Material Design 위젯들을 사용하기 위한 패키지
import 'package:flutter/material.dart';
// 로딩 화면 (앱 시작 시 단어 로딩)
import 'screens/loading_screen.dart';
// 한국어 locale 초기화를 위한 패키지
import 'package:intl/date_symbol_data_local.dart';
// 알림 서비스
import 'services/notification_service.dart';
// 상태 관리
import 'package:provider/provider.dart';
// 테마 프로바이더
import 'providers/theme_provider.dart';
// 단어 관리 프로바이더
import 'providers/word_provider.dart';
// 통계 관리 프로바이더
import 'providers/statistics_provider.dart';
// 설정 관리 프로바이더
import 'providers/settings_provider.dart';

// 앱의 시작점 (진입점)
// async: 비동기 함수 - await를 사용할 수 있음
void main() async {
  // Flutter 엔진을 초기화 (비동기 작업 전에 필수)
  // 데이터베이스 같은 네이티브 기능을 사용하기 전에 반드시 호출해야 함
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 locale 데이터 초기화 (DateFormat에서 'ko_KR' 사용하기 위해 필수)
  await initializeDateFormatting('ko_KR', null);

  // 알림 서비스 초기화
  await NotificationService.instance.initialize();

  // 앱 실행 (로딩 화면부터 시작)
  runApp(
    MultiProvider(
      providers: [
        // 테마 관리
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // 단어 데이터 관리
        ChangeNotifierProvider(create: (_) => WordProvider()),
        // 통계 데이터 관리
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        // 설정 관리
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// 앱의 루트 위젯
// StatelessWidget: 상태가 변하지 않는 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 화면을 그리는 메서드
  @override
  Widget build(BuildContext context) {
    // MaterialApp: Material Design을 사용하는 앱의 루트 위젯
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Daily Voca', // 앱 이름 (멀티태스킹 화면에 표시)
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const LoadingScreen(), // 앱이 시작될 때 보여줄 첫 화면 (로딩 화면)
        );
      },
    );
  }
}
