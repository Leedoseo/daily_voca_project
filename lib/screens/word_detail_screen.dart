// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// TTS (Text-to-Speech) 기능을 제공하는 패키지
import 'package:flutter_tts/flutter_tts.dart';
// 단어 모델
import '../models/word.dart';
// Provider
import 'package:provider/provider.dart';
// 단어 관리 Provider
import '../providers/word_provider.dart';
// 단어 수정 화면
import 'edit_word_screen.dart';

/// 단어 상세 화면
/// 단어의 상세 정보와 발음 듣기 기능을 제공
class WordDetailScreen extends StatefulWidget {
  // 표시할 단어 객체
  final Word word;

  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

/// WordDetailScreen의 상태 관리 클래스
class _WordDetailScreenState extends State<WordDetailScreen> {
  // TTS 엔진 인스턴스
  final FlutterTts _flutterTts = FlutterTts();

  // 현재 발음 재생 중인지 여부
  bool _isSpeaking = false;

  /// 위젯이 생성될 때 한 번만 호출
  @override
  void initState() {
    super.initState();
    // TTS 엔진 초기화
    _initTts();
  }

  /// TTS 엔진 설정 초기화
  Future<void> _initTts() async {
    // 언어를 미국 영어로 설정
    await _flutterTts.setLanguage('en-US');

    // 발음 속도 설정 (0.0 ~ 1.0, 0.5는 절반 속도)
    await _flutterTts.setSpeechRate(0.5);

    // 볼륨 설정 (0.0 ~ 1.0)
    await _flutterTts.setVolume(1.0);

    // 음높이 설정 (0.5 ~ 2.0, 1.0이 기본)
    await _flutterTts.setPitch(1.0);

    // 발음이 끝났을 때 호출되는 콜백 함수 등록
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  /// 발음 재생/정지 토글 함수
  Future<void> _speak() async {
    if (_isSpeaking) {
      // 이미 재생 중이면 정지
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      // 재생 중이 아니면 발음 시작
      setState(() {
        _isSpeaking = true;
      });
      // widget.word: StatefulWidget의 부모 위젯(WordDetailScreen)의 속성에 접근
      await _flutterTts.speak(widget.word.word);
    }
  }

  /// 단어 삭제 처리
  Future<void> _deleteWord() async {
    // 삭제 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단어 삭제'),
        content: Text('\'${widget.word.word}\'를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // 사용자가 삭제 확인한 경우
    if (confirmed == true && mounted) {
      final wordProvider = Provider.of<WordProvider>(context, listen: false);
      final success = await wordProvider.deleteWord(widget.word.id!);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('단어가 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          // 이전 화면으로 돌아가기 (true: 목록 새로고침 필요)
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: ${wordProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 위젯이 제거될 때 호출 (메모리 누수 방지)
  @override
  void dispose() {
    // TTS 재생 중지
    _flutterTts.stop();
    super.dispose();
  }

  /// 화면을 그리는 메서드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 상세'),
        actions: [
          // 수정 버튼
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // 수정 화면으로 이동
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditWordScreen(word: widget.word),
                ),
              );
              // 수정되었으면 이전 화면으로 돌아가기 (목록 새로고침 필요)
              if (mounted && result == true) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          // 삭제 버튼
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteWord,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          // 왼쪽 정렬
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 단어와 발음 듣기 버튼을 중앙에 배치
            Center(
              child: Column(
                children: [
                  // 영어 단어 표시
                  Text(
                    widget.word.word,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16), // 세로 간격

                  // 발음 듣기 버튼
                  ElevatedButton.icon(
                    onPressed: _speak, // 버튼 클릭 시 _speak 함수 호출
                    // 삼항 연산자: 조건 ? 참일때값 : 거짓일때값
                    icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                    label: Text(_isSpeaking ? '정지' : '발음 듣기'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 뜻 섹션
            const Text(
              '뜻',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.word.meaning, style: const TextStyle(fontSize: 24)),

            const SizedBox(height: 32),

            // 예문 섹션
            const Text(
              '예문',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),

            // 예문을 박스 안에 표시
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // shade: 색상의 명도 조절 (50 ~ 900)
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12), // 모서리 둥글게
              ),
              child: Text(
                widget.word.example,
                style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic, // 이탤릭체
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
