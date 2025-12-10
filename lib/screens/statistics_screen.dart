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
// 플래시카드 학습 화면
import 'flashcard_study_screen.dart';
// 차트 라이브러리
import 'package:fl_chart/fl_chart.dart';

/// 통계 화면
/// 학습 통계를 보여주는 화면 (차트 포함)
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

/// StatisticsScreen의 상태 관리 클래스
class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  // DB 서비스 인스턴스
  final DatabaseService _dbService = DatabaseService.instance;

  // 탭 컨트롤러
  late TabController _tabController;

  // 로딩 중 여부
  bool _isLoading = true;

  // 오늘 통계 데이터
  int _totalStudied = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;
  double _accuracy = 0.0;

  // 주간/월간 통계 데이터
  List<Map<String, dynamic>> _weeklyStats = [];
  List<Map<String, dynamic>> _monthlyStats = [];

  // 단어별 통계
  List<Map<String, dynamic>> _mostIncorrectWords = [];
  List<Map<String, dynamic>> _mostCorrectWords = [];

  /// 위젯이 생성될 때 한 번만 호출
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 통계 로드
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 통계를 데이터베이스에서 가져오기
  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // 오늘 날짜
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 오늘의 학습 통계 조회
      final todayStats = await _dbService.getStudyStatisticsByDate(today);

      // 주간 통계 (최근 7일)
      final weeklyStats = await _dbService.getRecentDaysStatistics(7);

      // 월간 통계 (최근 30일)
      final monthlyStats = await _dbService.getRecentDaysStatistics(30);

      // 단어별 통계
      final mostIncorrectWords = await _dbService.getMostIncorrectWords(5);
      final mostCorrectWords = await _dbService.getMostCorrectWords(5);

      // 통계 계산
      final totalStudied = todayStats['totalStudied'] ?? 0;
      final correctCount = todayStats['correctCount'] ?? 0;
      final incorrectCount = todayStats['incorrectCount'] ?? 0;
      final accuracy = totalStudied > 0
          ? (correctCount / totalStudied * 100)
          : 0.0;

      setState(() {
        _totalStudied = totalStudied;
        _correctCount = correctCount;
        _incorrectCount = incorrectCount;
        _accuracy = accuracy;
        _weeklyStats = weeklyStats;
        _monthlyStats = monthlyStats;
        _mostIncorrectWords = mostIncorrectWords;
        _mostCorrectWords = mostCorrectWords;
        _isLoading = false;
      });
    } catch (e) {
      // 에러 발생 시 기본값으로 설정
      setState(() {
        _totalStudied = 0;
        _correctCount = 0;
        _incorrectCount = 0;
        _accuracy = 0.0;
        _weeklyStats = [];
        _monthlyStats = [];
        _mostIncorrectWords = [];
        _mostCorrectWords = [];
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
      appBar: AppBar(
        title: const Text('통계'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '오늘', icon: Icon(Icons.today)),
            Tab(text: '주간', icon: Icon(Icons.view_week)),
            Tab(text: '월간', icon: Icon(Icons.calendar_month)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 오늘 탭
          _buildTodayTab(),
          // 주간 탭
          _buildWeeklyTab(),
          // 월간 탭
          _buildMonthlyTab(),
        ],
      ),
    );
  }

  /// 오늘 탭
  Widget _buildTodayTab() {
    if (_totalStudied == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
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
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
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
              const SizedBox(width: 12),
              // 전체 기록 보기 버튼
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard('총 학습 단어', _totalStudied.toString(), Icons.book, Colors.blue),
              _buildStatCard('정확도', '${_accuracy.toStringAsFixed(1)}%', Icons.check_circle, Colors.green),
              _buildStatCard('알고 있음', _correctCount.toString(), Icons.thumb_up, Colors.teal),
              _buildStatCard('모름', _incorrectCount.toString(), Icons.thumb_down, Colors.red),
            ],
          ),
          const SizedBox(height: 32),

          // 단어별 통계
          if (_mostIncorrectWords.isNotEmpty || _mostCorrectWords.isNotEmpty)
            _buildWordStatistics(),
        ],
      ),
    );
  }

  /// 주간 탭
  Widget _buildWeeklyTab() {
    return _buildChartTab(_weeklyStats, '주간', 7);
  }

  /// 월간 탭
  Widget _buildMonthlyTab() {
    return _buildChartTab(_monthlyStats, '월간', 30);
  }

  /// 차트 탭 위젯
  Widget _buildChartTab(List<Map<String, dynamic>> stats, String title, int days) {
    if (stats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '학습 데이터가 없습니다',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 학습량 차트
          Text(
            '$title 학습량',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildStudyCountChart(stats, days),
          ),
          const SizedBox(height: 32),

          // 정확도 차트
          Text(
            '$title 정확도',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildAccuracyChart(stats, days),
          ),
          const SizedBox(height: 32),

          // 전체 기록 버튼
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudyHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('전체 기록 보기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 학습량 차트
  Widget _buildStudyCountChart(List<Map<String, dynamic>> stats, int days) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: days == 7 ? 1 : 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= stats.length) return const Text('');
                final date = DateTime.parse(stats[value.toInt()]['date']);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(date),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: stats.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['totalStudied'] as int).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
        minY: 0,
      ),
    );
  }

  /// 정확도 차트
  Widget _buildAccuracyChart(List<Map<String, dynamic>> stats, int days) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: days == 7 ? 1 : 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= stats.length) return const Text('');
                final date = DateTime.parse(stats[value.toInt()]['date']);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(date),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: stats.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['accuracy'] as double),
              );
            }).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }

  /// 단어별 통계 위젯
  Widget _buildWordStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 가장 많이 틀린 단어
        if (_mostIncorrectWords.isNotEmpty) ...[
          const Text(
            '가장 많이 틀린 단어 TOP 5',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mostIncorrectWords.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final word = _mostIncorrectWords[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    word['word'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(word['meaning'] as String),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${word['incorrectCount']}회',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 가장 잘 아는 단어
        if (_mostCorrectWords.isNotEmpty) ...[
          const Text(
            '가장 잘 아는 단어 TOP 5',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mostCorrectWords.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final word = _mostCorrectWords[index];
                final accuracy = word['accuracy'] as double;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    word['word'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(word['meaning'] as String),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${accuracy.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// 빈 상태 위젯 (학습 기록이 없을 때)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 120,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 32),
            Text(
              '오늘의 학습 기록이 없습니다',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '학습을 시작하면\n여기에 통계가 표시됩니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                // 학습 화면으로 이동 (플래시카드)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FlashcardStudyScreen(),
                  ),
                ).then((_) => _loadStatistics());
              },
              icon: const Icon(Icons.school, size: 28),
              label: const Text(
                '학습 시작하기',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
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
              label: const Text('전체 기록 보기'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 20,
                ),
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
