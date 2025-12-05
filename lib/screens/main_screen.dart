// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// 하단 탭의 각 화면들
import 'home_screen.dart';
import 'study_screen.dart';
import 'statistics_screen.dart';

/// 메인 화면
/// 하단 네비게이션 바를 통해 3개의 탭(홈/학습/통계)을 전환하는 화면
/// StatefulWidget: 상태가 변하는 위젯 (현재 선택된 탭이 변함)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  // State 객체 생성
  State<MainScreen> createState() => _MainScreenState();
}

/// MainScreen의 상태를 관리하는 클래스
class _MainScreenState extends State<MainScreen> {
  // 현재 선택된 탭의 인덱스 (0: 홈, 1: 학습, 2: 통계)
  int _currentIndex = 0;

  // 각 탭에 표시될 화면들의 리스트
  // final: 한 번 할당되면 변경 불가
  // const: 컴파일 시점에 값이 결정되는 상수
  final List<Widget> _screens = const [
    HomeScreen(),        // 인덱스 0
    StudyScreen(),       // 인덱스 1
    StatisticsScreen(),  // 인덱스 2
  ];

  /// 화면을 그리는 메서드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 선택된 인덱스에 해당하는 화면 표시
      // 예: _currentIndex가 1이면 _screens[1]인 StudyScreen()이 표시됨
      body: _screens[_currentIndex],

      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        // 현재 선택된 탭 표시
        currentIndex: _currentIndex,

        // 탭을 탭했을 때 호출되는 콜백 함수
        // index: 탭한 탭의 인덱스 (0, 1, 2)
        onTap: (index) {
          // setState: 상태를 변경하고 화면을 다시 그림
          setState(() {
            _currentIndex = index; // 선택된 탭 인덱스 업데이트
          });
        },

        // 네비게이션 바의 탭 아이템들
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: '학습'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '통계'),
        ],
      ),
    );
  }
}
