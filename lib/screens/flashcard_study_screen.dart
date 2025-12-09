// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// 햅틱 피드백
import 'package:flutter/services.dart';
// 카드 스와이프 기능을 제공하는 외부 패키지
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
// 단어 모델
import '../models/word.dart';
// 데이터베이스 서비스
import '../services/database_service.dart';
// 날짜 포맷팅 패키지
import 'package:intl/intl.dart';
// 학습 기록 모델
import '../models/study_record.dart';
// SharedPreferences (튜토리얼 표시 여부 저장)
import 'package:shared_preferences/shared_preferences.dart';
// TTS 서비스
import '../services/tts_service.dart';

/// 플래시카드 학습 화면
/// StatefulWidget: 상태가 변하는 위젯 (단어 목록, 현재 인덱스 등이 변함)
class FlashcardStudyScreen extends StatefulWidget {
  // 복습 모드 여부 (true: 틀린 단어만, false: 전체 단어)
  final bool isReviewMode;

  const FlashcardStudyScreen({super.key, this.isReviewMode = false});

  @override
  // State 객체 생성
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

/// FlashcardStudyScreen의 상태를 관리하는 클래스
class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  // 데이터베이스 서비스 인스턴스
  final DatabaseService _dbService = DatabaseService.instance;

  // 학습할 단어 목록
  List<Word> _words = [];

  // 로딩 중 여부
  bool _isLoading = true;

  // 현재 보고 있는 카드의 인덱스
  int _currentIndex = 0;

  // 카드 스와이프를 제어하는 컨트롤러
  final CardSwiperController _cardController = CardSwiperController();

  // 학습 통계 (맞힌 개수, 틀린 개수)
  int _correctCount = 0;
  int _incorrectCount = 0;

  // Undo 기능을 위한 변수들
  int? _lastWordIndex; // 마지막으로 스와이프한 단어 인덱스
  CardSwiperDirection? _lastDirection; // 마지막 스와이프 방향
  int? _lastRecordId; // 마지막으로 저장한 학습 기록 ID (삭제용)
  bool _canUndo = false; // Undo 가능 여부

  // 튜토리얼 표시 여부
  bool _showTutorial = false;

  /// 위젯이 생성될 때 한 번만 호출되는 메서드
  @override
  void initState() {
    super.initState();
    // 단어 목록 로드
    _loadWords();
    // 튜토리얼 확인
    _checkTutorial();
    // TTS 초기화
    TtsService.instance.initialize();
  }

  /// 튜토리얼을 보여줄지 확인
  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenFlashcardTutorial') ?? false;

    if (!hasSeenTutorial) {
      // 0.5초 후에 튜토리얼 표시 (화면 로드 후)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showTutorial = true;
          });
        }
      });
    }
  }

  /// 튜토리얼 닫기
  Future<void> _closeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenFlashcardTutorial', true);
    setState(() {
      _showTutorial = false;
    });
  }

  /// 데이터베이스에서 단어 목록 가져오기
  Future<void> _loadWords() async {
    // 로딩 상태 시작
    setState(() => _isLoading = true);

    // 복습 모드면 틀린 단어만, 아니면 전체 단어 조회
    final words = widget.isReviewMode
        ? await _dbService.getIncorrectWords()
        : await _dbService.getAllWords();

    // 화면 업데이트 (setState 호출 시 build 메서드가 다시 실행됨)
    setState(() {
      _words = words;
      _isLoading = false;
    });
  }

  /// 카드를 스와이프할 때 호출되는 콜백 함수
  /// previousIndex: 이전 카드의 인덱스
  /// currentIndex: 현재 카드의 인덱스 (null이면 마지막 카드)
  /// direction: 스와이프 방향 (left, right, up, down)
  /// 반환값: true면 스와이프 허용, false면 취소
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // 햅틱 피드백 (진동)
    HapticFeedback.lightImpact();

    _saveStudyRecord(previousIndex, direction);

    // 학습 통계 업데이트
    setState(() {
      if (direction == CardSwiperDirection.right) {
        _correctCount++; // 오른쪽 스와이프 = 알고있음
      } else if (direction == CardSwiperDirection.left) {
        _incorrectCount++; // 왼쪽 스와이프 = 모름
      }

      // 현재 인덱스 업데이트
      if (currentIndex != null) {
        _currentIndex = currentIndex;
      }
    });

    // 마지막 카드를 넘긴 경우 (모든 학습 완료)
    if (currentIndex == null || previousIndex == _words.length - 1) {
      // 300ms 후에 완료 다이얼로그 표시 (애니메이션 완료 대기)
      Future.delayed(const Duration(milliseconds: 300), () {
        _showCompletionDialog();
      });
    }

    return true; // 스와이프 허용
  }

  /// 학습 기록을 DB에 저장
  Future<void> _saveStudyRecord(
    int wordIndex,
    CardSwiperDirection direction,
  ) async {
    try {
      final word = _words[wordIndex];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result =
          direction == CardSwiperDirection.right; // 오른쪽 = 알고있음, 왼쪽 = 모름

      final record = StudyRecord(
        date: today,
        wordId: word.id!,
        result: result,
        isReview: widget.isReviewMode, // 복습 모드 여부 전달
      );

      final recordId = await _dbService.insertStudyRecord(record);

      // Undo를 위한 정보 저장
      setState(() {
        _lastWordIndex = wordIndex;
        _lastDirection = direction;
        _lastRecordId = recordId;
        _canUndo = true;
      });

      print('학습 기록 저장: ${word.word}, 결과: $result, 복습: ${widget.isReviewMode}'); // 디버깅용
    } catch (e) {
      print('학습 기록 저장 실패: $e'); // 디버깅용
    }
  }

  /// Undo 기능 - 마지막 스와이프 되돌리기
  Future<void> _undoLastSwipe() async {
    if (!_canUndo || _lastRecordId == null || _lastWordIndex == null) return;

    try {
      // 햅틱 피드백
      HapticFeedback.mediumImpact();

      // 데이터베이스에서 마지막 기록 삭제
      await _dbService.deleteStudyRecord(_lastRecordId!);

      // 통계 및 인덱스 되돌리기
      setState(() {
        if (_lastDirection == CardSwiperDirection.right) {
          _correctCount = _correctCount > 0 ? _correctCount - 1 : 0;
        } else if (_lastDirection == CardSwiperDirection.left) {
          _incorrectCount = _incorrectCount > 0 ? _incorrectCount - 1 : 0;
        }

        // 현재 인덱스를 이전 카드로 되돌리기
        _currentIndex = _lastWordIndex!;

        // Undo 상태 리셋
        _canUndo = false;
        _lastRecordId = null;
        _lastDirection = null;
        _lastWordIndex = null;
      });

      // 카드 되돌리기
      _cardController.undo();

      print('Undo 완료'); // 디버깅용
    } catch (e) {
      print('Undo 실패: $e'); // 디버깅용
    }
  }

  /// 모든 카드 학습 완료 시 표시되는 다이얼로그
  void _showCompletionDialog() {
    // 정답률 계산
    final totalCount = _correctCount + _incorrectCount;
    final accuracyRate = totalCount > 0 ? (_correctCount / totalCount * 100).round() : 0;

    // 정답률에 따른 메시지와 아이콘 결정
    String message;
    IconData icon;
    Color iconColor;

    if (accuracyRate >= 80) {
      message = '훌륭해요! 🎉';
      icon = Icons.emoji_events; // 트로피
      iconColor = Colors.amber;
    } else if (accuracyRate >= 60) {
      message = '잘했어요! 👍';
      icon = Icons.thumb_up;
      iconColor = Colors.blue;
    } else if (accuracyRate >= 40) {
      message = '계속 노력해요! 💪';
      icon = Icons.trending_up;
      iconColor = Colors.orange;
    } else {
      message = '다시 복습해봐요! 📚';
      icon = Icons.refresh;
      iconColor = Colors.red;
    }

    // showDialog: 팝업 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 8),
            Text(widget.isReviewMode ? '복습 완료!' : '학습 완료!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 메시지
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // 통계 요약
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 정답률
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$accuracyRate%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '정답률',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Divider(height: 24),

                  // 맞힌 개수 / 틀린 개수
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 맞힌 개수
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '$_correctCount개',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '맞힌 단어',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      // 틀린 개수
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '$_incorrectCount개',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '틀린 단어',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // pop() 두 번 호출: 다이얼로그 닫기 + 학습 화면 닫기
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 이전 화면으로 돌아가기
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 화면을 그리는 메서드
  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때 로딩 인디케이터 표시
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 단어 목록이 비어있을 때
    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isReviewMode ? '복습하기' : '학습하기'),
        ),
        body: Center(
          child: Text(
            widget.isReviewMode ? '복습할 단어가 없습니다.\n먼저 학습을 진행해주세요!' : '학습할 단어가 없습니다',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // 정상적으로 단어가 있을 때 플래시카드 화면 표시
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReviewMode ? '복습 학습' : '플래시카드 학습'),
        // AppBar 오른쪽 영역에 위젯 배치
        actions: [
          // Undo 버튼
          IconButton(
            onPressed: _canUndo ? _undoLastSwipe : null,
            icon: const Icon(Icons.undo),
            tooltip: '되돌리기',
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              // 현재 진행 상황 표시 (예: "3 / 50")
              child: Text(
                '${_currentIndex + 1} / ${_words.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 상단 진행률 바
              LinearProgressIndicator(
                // value: 0.0 ~ 1.0 사이의 값 (현재 진행률)
                value: (_currentIndex + 1) / _words.length,
                minHeight: 6,
                // 복습 모드일 때는 주황색 진행률 바
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isReviewMode ? Colors.orange : Colors.blue,
                ),
              ),

              // Expanded: 남은 공간을 모두 차지
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  // CardSwiper: 카드 스와이프 위젯
                  child: CardSwiper(
                    controller: _cardController,
                    cardsCount: _words.length, // 총 카드 개수
                    numberOfCardsDisplayed: 2, // 동시에 표시할 카드 개수
                    onSwipe: _onSwipe, // 스와이프 콜백
                    // cardBuilder: 각 카드를 그리는 함수
                    // index: 카드 인덱스
                    // percentThresholdX, percentThresholdY: 스와이프 진행률 (사용 안 함)
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      return FlashcardWidget(word: _words[index]);
                    },
                  ),
                ),
              ),

              // 하단 버튼 영역
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  // 버튼들을 균등하게 배치
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // "모름" 버튼 (왼쪽 스와이프)
                    ElevatedButton.icon(
                      onPressed: () {
                        // 프로그래밍 방식으로 왼쪽 스와이프 실행
                        _cardController.swipe(CardSwiperDirection.left);
                      },
                      icon: const Icon(Icons.close, size: 32),
                      label: const Text('모름'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400, // 빨간색 배경
                        foregroundColor: Colors.white, // 흰색 텍스트
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    // "알고있음" 버튼 (오른쪽 스와이프)
                    ElevatedButton.icon(
                      onPressed: () {
                        // 프로그래밍 방식으로 오른쪽 스와이프 실행
                        _cardController.swipe(CardSwiperDirection.right);
                      },
                      icon: const Icon(Icons.check, size: 32),
                      label: const Text('알고있음'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400, // 초록색 배경
                        foregroundColor: Colors.white, // 흰색 텍스트
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 튜토리얼 오버레이
          if (_showTutorial)
            GestureDetector(
              onTap: _closeTutorial,
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.swipe,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '플래시카드 사용법',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  size: 48,
                                  color: Colors.red.shade300,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '왼쪽으로 스와이프\n모름',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.arrow_forward,
                                  size: 48,
                                  color: Colors.green.shade300,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '오른쪽으로 스와이프\n알고있음',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.touch_app, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '카드를 탭하면 뜻을 볼 수 있습니다',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.undo, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '되돌리기 버튼으로 실수를 취소할 수 있습니다',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          '화면을 탭하여 시작하기',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 위젯이 제거될 때 호출 (메모리 누수 방지)
  @override
  void dispose() {
    // 컨트롤러 리소스 해제
    _cardController.dispose();
    super.dispose();
  }
}

/// 플래시카드 위젯
/// 앞면(단어)과 뒷면(뜻+예문)을 토글할 수 있는 카드
class FlashcardWidget extends StatefulWidget {
  // 표시할 단어 객체
  final Word word;

  const FlashcardWidget({super.key, required this.word});

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

/// FlashcardWidget의 상태 관리 클래스
class _FlashcardWidgetState extends State<FlashcardWidget> {
  // 답(뜻)을 보여줄지 여부 (false: 단어 표시, true: 뜻 표시)
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    // GestureDetector: 터치 제스처를 감지하는 위젯
    return GestureDetector(
      // onTap: 탭했을 때 호출되는 콜백
      onTap: () {
        setState(() {
          // !: NOT 연산자 (true ↔ false 토글)
          _showAnswer = !_showAnswer;
        });
      },
      child: Card(
        elevation: 8, // 그림자 깊이
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // LinearGradient: 선형 그라데이션 배경
            gradient: LinearGradient(
              begin: Alignment.topLeft, // 왼쪽 위에서 시작
              end: Alignment.bottomRight, // 오른쪽 아래로 끝
              // 삼항 연산자로 앞/뒷면에 따라 색상 변경
              colors: _showAnswer
                  ? [Colors.blue.shade300, Colors.blue.shade600]
                  : [Colors.purple.shade300, Colors.purple.shade600],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // if 문으로 조건부 렌더링
                  // ...[]: spread 연산자 - 리스트의 요소들을 펼침
                  if (!_showAnswer) ...[
                    // 앞면: 단어 표시
                    Text(
                      widget.word.word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // 발음 듣기 버튼
                    ElevatedButton.icon(
                      onPressed: () {
                        // TTS로 단어 발음 재생
                        TtsService.instance.speak(widget.word.word);
                      },
                      icon: const Icon(Icons.volume_up, size: 28),
                      label: const Text('발음 듣기', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '탭하여 뜻 보기',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70, // 반투명 흰색
                      ),
                    ),
                  ] else ...[
                    // 뒷면: 뜻과 예문 표시 (스크롤 가능)
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.word.meaning,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // 예문을 반투명 박스 안에 표시
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                // withOpacity: 투명도 설정 (0.0 ~ 1.0)
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.word.example,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '탭하여 단어 보기',
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}