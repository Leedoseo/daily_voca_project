// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// DB 서비스
import '../services/database_service.dart';
// 날짜 포맷팅 패키지
import 'package:intl/intl.dart';
// 학습 기록 상세 화면
import 'study_record_detail_screen.dart';
// 학습 기록 히스토리 화면
import 'study_history_screen.dart';

/// 통계 화면
/// 학습 통계를 보여주는 화면 (현재는 플레이스홀더)
/// StatelessWidget: 상태가 변하지 않는 정적 위젯 -> fulWidget으로 변경 : DB에서 통계를 가져와서 표시하기 위함
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

/// StatisticsScreen의 상태 관리 클래스
class _StatisticsScreenState extends State<StatisticsScreen> {
  // DB 서비스 인스턴스
  final DatabaseService _dbService = DatabaseService.instance;

  // 로딩 중 여부
  bool _isLoading = true;

  // 통계 데이터
  int _totalStudied = 0; // 오늘 학습한 총 단어 수
  int _correctCount = 0; // 맞힌 단어 수
  int _incorrectCount = 0; // 틀린 단어 수
  double _accuracy = 0.0; // 정확도 (%)

  /// 위젯이 생성될 때 한 번만 호출
  @override
  void initState() {
    super.initState();
    // 통계 로드
    _loadStatistics();
  }

  /// 오늘의 학습 통계를 데이터베이스에서 가져오기
  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // 오늘 날짜
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 오늘의 학습 통계 조회 (고유 단어 기준)
      final stats = await _dbService.getStudyStatisticsByDate(today);

      // 통계 계산
      final totalStudied = stats['totalStudied'] ?? 0;
      final correctCount = stats['correctCount'] ?? 0;
      final incorrectCount = stats['incorrectCount'] ?? 0;
      final accuracy = totalStudied > 0
          ? (correctCount / totalStudied * 100)
          : 0.0;

      setState(() {
        _totalStudied = totalStudied;
        _correctCount = correctCount;
        _incorrectCount = incorrectCount;
        _accuracy = accuracy;
        _isLoading = false;
      });
    } catch (e) {
      // 에러 발생 시 기본값으로 설정
      setState(() {
        _totalStudied = 0;
        _correctCount = 0;
        _incorrectCount = 0;
        _accuracy = 0.0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때 로딩 인디케이터 표시
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      // 통계 카드를 표시하는 UI
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 오늘 날짜 표시
            Text(
              '오늘의 학습 (${DateFormat('yyyy년 MM월 dd일').format(DateTime.now())})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 버튼들
            Row(
              children: [
                // 오늘 상세 보기 버튼
                if (_totalStudied > 0)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 오늘 날짜로 상세 화면 이동
                        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudyRecordDetailScreen(date: today),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('오늘 상세'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (_totalStudied > 0) const SizedBox(width: 12),
                // 전체 기록 보기 버튼
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 학습 기록 히스토리 화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudyHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('전체 기록'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 통계 카드들
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // 2열 그리드
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // 총 학습 단어 수 카드
                  _buildStatCard(
                    '총 학습 단어',
                    _totalStudied.toString(),
                    Icons.book,
                    Colors.blue,
                  ),
                  // 정확도 카드
                  _buildStatCard(
                    '정확도',
                    '${_accuracy.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  // 맞힌 단어 카드
                  _buildStatCard(
                    '알고 있음',
                    _correctCount.toString(),
                    Icons.thumb_up,
                    Colors.teal,
                  ),
                  // 틀린 단어 카드
                  _buildStatCard(
                    '모름',
                    _incorrectCount.toString(),
                    Icons.thumb_down,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 통계 카드 위젯 생성 헬퍼 메서드
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.7), color],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
