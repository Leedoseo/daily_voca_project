// Flutter의 핵심 Material Design 위젯들을 사용하기 위한 패키지
import 'package:flutter/material.dart';
// 메인 화면 (BottomNavigationBar가 있는 화면)
import 'screens/main_screen.dart';
// 데이터베이스 서비스 (SQLite 관리)
import 'services/database_service.dart';
// 초기 단어 데이터 (50개의 토익 필수 단어)
import 'utils/initial_data.dart';
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

  // 데이터베이스 서비스의 싱글톤 인스턴스 가져오기
  // 싱글톤: 앱 전체에서 하나의 인스턴스만 사용
  final dbService = DatabaseService.instance;

  // await: 비동기 작업이 완료될 때까지 기다림
  // 데이터베이스에 저장된 단어 개수를 가져옴
  final wordCount = await dbService.getWordCount();

  // 데이터베이스가 비어있으면 (처음 실행할 때)
  if (wordCount == 0) {
    // 50개의 초기 단어 데이터를 데이터베이스에 삽입
    await dbService.initializeWithWords(InitialData.words);
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
      ),
      home: const MainScreen(), // 앱이 시작될 때 보여줄 첫 화면
    );
  }
}
