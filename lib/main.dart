// Flutter의 핵심 Material Design 위젯들을 사용하기 위한 패키지
import 'package:flutter/material.dart';
// 메인 화면 (BottomNavigationBar가 있는 화면)
import 'screens/main_screen.dart';
// 데이터베이스 서비스 (SQLite 관리)
import 'services/database_service.dart';
// 단어 API 서비스 (랜덤 단어 가져오기)
import 'services/word_api_service.dart';
// SharedPreferences 서비스 (앱 설정 저장)
import 'services/preferences_service.dart';
// 한국어 locale 초기화를 위한 패키지
import 'package:intl/date_symbol_data_local.dart';

// 앱의 시작점 (진입점)
// async: 비동기 함수 - await를 사용할 수 있음
void main() async {
  // Flutter 엔진을 초기화 (비동기 작업 전에 필수)
  // 데이터베이스 같은 네이티브 기능을 사용하기 전에 반드시 호출해야 함
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 locale 데이터 초기화 (DateFormat에서 'ko_KR' 사용하기 위해 필수)
  await initializeDateFormatting('ko_KR', null);

  // 서비스 인스턴스 가져오기
  final dbService = DatabaseService.instance;
  final prefsService = PreferencesService.instance;
  final apiService = WordApiService.instance;

  // SharedPreferences 초기화
  await prefsService.init();

  // 단어 갱신이 필요한지 확인 (일단위)
  if (prefsService.shouldUpdateWords()) {
    // 기존 단어 모두 삭제
    await dbService.deleteAllWords();

    // API에서 랜덤 단어 50개를 가져와서 데이터베이스에 삽입
    final words = await apiService.fetchRandomWords();
    await dbService.initializeWithWords(words);

    // 마지막 갱신 날짜 저장
    await prefsService.setLastWordUpdateDate(prefsService.getTodayDate());
  }

  // 앱 실행
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
      home: const MainScreen(), // 앱이 시작될 때 보여줄 첫 화면
    );
  }
}
