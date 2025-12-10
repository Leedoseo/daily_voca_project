// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// DB 서비스
import '../services/database_service.dart';
// 날짜 포맷팅 패키지
import 'package:intl/intl.dart';
// 플래시카드 학습 화면
import 'flashcard_study_screen.dart';
// 단어 추가 화면
import 'add_word_screen.dart';
// 설정 화면
import 'settings_screen.dart';

/// 홈 화면
/// 앱의 메인 대시보드 - 오늘의 학습 목표와 통계를 표시
/// StatefulWidget으로 변경: DB에서 데이터를 가져와서 표시하기 위함
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// HomeScreen의 상태 관리 클래스
class _HomeScreenState extends State<HomeScreen> {
  // DB 서비스 인스턴스
  final DatabaseService _dbService = DatabaseService.instance;

  // 로딩 중 여부
  bool _isLoading = true;

  // 통계 데이터
  int _totalWords = 0; // 전체 단어 수
  int _todayStudied = 0; // 오늘 학습한 단어 수
  int _todayCorrect = 0; // 오늘 맞힌 단어 수
  double _todayAccuracy = 0.0; // 오늘 정확도

  /// 위젯이 생성될 때 한 번만 호출
  @override
  void initState() {
    super.initState();
    // 통계 로드
    _loadStatistics();
  }

  /// 대시보드 통계를 데이터베이스에서 가져오기
  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    // 전체 단어 수 조회
    final totalWords = await _dbService.getWordCount();

    // 오늘 날짜
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 오늘의 학습 통계 조회 (고유 단어 기준)
    final stats = await _dbService.getStudyStatisticsByDate(today);

    // 통계 계산
    final todayStudied = stats['totalStudied'] ?? 0;
    final todayCorrect = stats['correctCount'] ?? 0;
    final todayAccuracy =
        todayStudied > 0 ? (todayCorrect / todayStudied * 100) : 0.0;

    setState(() {
      _totalWords = totalWords;
      _todayStudied = todayStudied;
      _todayCorrect = todayCorrect;
      _todayAccuracy = todayAccuracy;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때 로딩 인디케이터 표시
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
      body: _totalWords == 0
          ? _buildEmptyState()
          : RefreshIndicator(
              // 아래로 당겨서 새로고침
              onRefresh: _loadStatistics,
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
              _buildProgressCard(),
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
                      '$_todayStudied',
                      Icons.book_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '정확도',
                      '${_todayAccuracy.toStringAsFixed(0)}%',
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
                      '$_todayCorrect',
                      Icons.thumb_up_outlined,
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '전체 단어',
                      '$_totalWords',
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
  }

  /// 빈 상태 위젯 (단어가 없을 때)
  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
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
                  ).then((_) => _loadStatistics());
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
  Widget _buildProgressCard() {
    // 오늘의 목표: 전체 단어 수 (나중에 사용자 설정으로 변경 가능)
    final goal = _totalWords;
    final progress = goal > 0 ? _todayStudied / goal : 0.0;

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
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$_todayStudied / $goal 단어 완료',
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
            _loadStatistics();
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