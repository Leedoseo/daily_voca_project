// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// 단어 목록 화면
import 'word_list_screen.dart';
// 플래시카드 학습 화면
import 'flashcard_study_screen.dart';
// 데이터베이스 서비스
import '../services/database_service.dart';

/// 학습 화면
/// 학습 시작 버튼과 단어 목록 버튼을 제공하는 허브 화면
/// StatefulWidget: 틀린 단어 개수를 동적으로 로드하기 위해 Stateful 사용
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

/// StudyScreen의 상태 관리 클래스
class _StudyScreenState extends State<StudyScreen> {
  // 데이터베이스 서비스
  final DatabaseService _dbService = DatabaseService.instance;

  // 틀린 단어 개수
  int _incorrectWordsCount = 0;

  // 로딩 중 여부
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncorrectWordsCount();
  }

  /// 틀린 단어 개수 로드
  Future<void> _loadIncorrectWordsCount() async {
    try {
      final count = await _dbService.getIncorrectWordsCount();
      setState(() {
        _incorrectWordsCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _incorrectWordsCount = 0;
        _isLoading = false;
      });
    }
  }

  /// 화면을 그리는 메서드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학습'),
      ),
      body: Center(
        child: Column(
          // 세로 방향 중앙 정렬
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 학습 아이콘
            const Icon(
              Icons.school,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),

            // 제목 텍스트
            const Text(
              '영어 단어 학습',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),

            // 학습 시작 버튼 (채워진 버튼)
            ElevatedButton.icon(
              onPressed: () {
                // Navigator.push: 새로운 화면으로 이동
                // context: 현재 위젯의 위치 정보
                // MaterialPageRoute: 화면 전환 애니메이션을 제공하는 라우트
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // builder: 표시할 화면을 반환하는 함수
                    builder: (context) => const FlashcardStudyScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow, size: 32),
              label: const Text('학습 시작하기', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48, // 좌우 패딩
                  vertical: 20,   // 상하 패딩
                ),
                backgroundColor: Colors.blue,    // 배경색
                foregroundColor: Colors.white,   // 텍스트/아이콘 색
              ),
            ),
            const SizedBox(height: 16),

            // 복습 시작 버튼 (주황색 버튼) - 새로 추가
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : (_incorrectWordsCount > 0
                      ? () async {
                          // 복습 모드로 플래시카드 학습 화면 열기
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FlashcardStudyScreen(
                                isReviewMode: true, // 복습 모드 활성화
                              ),
                            ),
                          );
                          // 복습 완료 후 돌아왔을 때 틀린 단어 개수 새로고침
                          _loadIncorrectWordsCount();
                        }
                      : null), // 틀린 단어가 없으면 버튼 비활성화
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, size: 32),
              label: Text(
                _isLoading
                    ? '로딩 중...'
                    : '틀린 단어 복습 ($_incorrectWordsCount개)',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 20,
                ),
                backgroundColor: Colors.orange, // 주황색 배경
                foregroundColor: Colors.white, // 흰색 텍스트
                disabledBackgroundColor: Colors.grey, // 비활성화 시 회색 배경
                disabledForegroundColor: Colors.white70, // 비활성화 시 반투명 흰색 텍스트
              ),
            ),
            const SizedBox(height: 16),

            // 단어 목록 버튼 (테두리만 있는 버튼)
            OutlinedButton.icon(
              onPressed: () {
                // 단어 목록 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WordListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('단어 목록 보기'),
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
}