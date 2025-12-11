// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// 날짜 포맷팅 패키지
import 'package:intl/intl.dart';
// 플래시카드 학습 화면
import 'flashcard_study_screen.dart';
// 단어 추가 화면
import 'add_word_screen.dart';
// 설정 화면
import 'settings_screen.dart';
// Provider
import 'package:provider/provider.dart';
// 단어 관리 Provider
import '../providers/word_provider.dart';
// 통계 관리 Provider
import '../providers/statistics_provider.dart';
// 설정 관리 Provider
import '../providers/settings_provider.dart';

/// 홈 화면
/// 앱의 메인 대시보드 - 오늘의 학습 목표와 통계를 표시
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// HomeScreen의 상태 관리 클래스
class _HomeScreenState extends State<HomeScreen> {
  /// 위젯이 생성될 때 한 번만 호출
  @override
  void initState() {
    super.initState();
    // Provider를 사용하여 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// 데이터 로드
  Future<void> _loadData() async {
    final wordProvider = Provider.of<WordProvider>(context, listen: false);
    final statsProvider = Provider.of<StatisticsProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    await Future.wait([
      wordProvider.fetchWordsFromDatabase(),
      statsProvider.loadStatistics(),
      settingsProvider.loadSettings(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<WordProvider, StatisticsProvider, SettingsProvider>(
      builder: (context, wordProvider, statsProvider, settingsProvider, child) {
        // 로딩 중일 때 로딩 인디케이터 표시
        if (statsProvider.isLoading || settingsProvider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final totalWords = wordProvider.words.length;
        final todayStudied = statsProvider.totalStudied;
        final todayCorrect = statsProvider.correctCount;
        final todayAccuracy = statsProvider.accuracy;
        final dailyGoal = settingsProvider.dailyGoal;

        return Scaffold(
          appBar: AppBar(
            title: const Text('홈'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: totalWords == 0
              ? _buildEmptyState()
              : RefreshIndicator(
                  // 아래로 당겨서 새로고침
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 환영 메시지
                        Text(
                          '안녕하세요!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR')
                              .format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 오늘의 학습 진행률 카드
                        _buildProgressCard(todayStudied, dailyGoal),
                        const SizedBox(height: 16),

                        // 빠른 학습 시작 버튼
                        _buildQuickStartButton(context),
                        const SizedBox(height: 24),

                        // 오늘의 통계 섹션
                        Text(
                          '오늘의 학습',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        // 통계 카드들 (2x2 그리드)
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                '학습한 단어',
                                '$todayStudied',
                                Icons.book_outlined,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                '정확도',
                                '${todayAccuracy.toStringAsFixed(0)}%',
                                Icons.check_circle_outline,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                '맞힌 단어',
                                '$todayCorrect',
                                Icons.thumb_up_outlined,
                                Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                '전체 단어',
                                '$totalWords',
                                Icons.library_books_outlined,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  /// 빈 상태 위젯 (단어가 없을 때)
  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 120,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 32),
              Text(
                '단어장이 비어있습니다',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '학습할 단어를 추가하고\n영어 실력을 키워보세요!',
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
                  // 단어 추가 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddWordScreen(),
                    ),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.add, size: 28),
                label: const Text(
                  '첫 단어 추가하기',
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
            ],
          ),
        ),
      ),
    );
  }

  /// 학습 진행률 카드 위젯
  Widget _buildProgressCard(int todayStudied, int dailyGoal) {
    final progress = dailyGoal > 0 ? todayStudied / dailyGoal : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.blue.shade700],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 학습 목표',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // 진행률 바
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                minHeight: 12,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$todayStudied / $dailyGoal 단어 완료',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 빠른 학습 시작 버튼
  Widget _buildQuickStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // 플래시카드 학습 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FlashcardStudyScreen(),
            ),
          ).then((_) {
            // 학습 화면에서 돌아왔을 때 통계 새로고침
            _loadData();
          });
        },
        icon: const Icon(Icons.play_arrow, size: 28),
        label: const Text('학습 시작하기', style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// 통계 카드 위젯
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
