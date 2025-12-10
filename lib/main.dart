// Flutter의 핵심 Material Design 위젯들을 사용하기 위한 패키지
import 'package:flutter/material.dart';
// 로딩 화면 (앱 시작 시 단어 로딩)
import 'screens/loading_screen.dart';
// 한국어 locale 초기화를 위한 패키지
import 'package:intl/date_symbol_data_local.dart';
// 알림 서비스
import 'services/notification_service.dart';

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
  runApp(const MyApp());
}

// 앱의 루트 위젯
// StatelessWidget: 상태가 변하지 않는 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 화면을 그리는 메서드
  @override
  Widget build(BuildContext context) {
    // MaterialApp: Material Design을 사용하는 앱의 루트 위젯
    return MaterialApp(
      title: 'Daily Voca', // 앱 이름 (멀티태스킹 화면에 표시)
      theme: ThemeData(
        // 앱 전체의 색상 테마 설정
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // Material Design 3 사용
        // AppBar 테마 설정
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        // ElevatedButton 테마 설정
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Card 테마 설정
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const LoadingScreen(), // 앱이 시작될 때 보여줄 첫 화면 (로딩 화면)
    );
  }
}
