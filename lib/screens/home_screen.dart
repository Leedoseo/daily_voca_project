// Flutter Material Design 위젯
import 'package:flutter/material.dart';

/// 홈 화면
/// 앱의 메인 대시보드 (현재는 플레이스홀더)
/// StatelessWidget: 상태가 변하지 않는 정적 위젯
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// 화면을 그리는 메서드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
      ),
      // Center: 자식 위젯을 가운데 정렬
      body: const Center(
        child: Text('홈 화면'),
      ),
    );
  }
}
