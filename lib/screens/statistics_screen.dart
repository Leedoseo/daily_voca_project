// Flutter Material Design 위젯
import 'package:flutter/material.dart';

/// 통계 화면
/// 학습 통계를 보여주는 화면 (현재는 플레이스홀더)
/// StatelessWidget: 상태가 변하지 않는 정적 위젯
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  /// 화면을 그리는 메서드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
      ),
      // Center: 자식 위젯을 가운데 정렬
      body: const Center(
        child: Text('통계 화면'),
      ),
    );
  }
}
