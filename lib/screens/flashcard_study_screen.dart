import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/word.dart';
import '../services/database_service.dart';

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({super.key});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  List<Word> _words = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final CardSwiperController _cardController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    final words = await _dbService.getAllWords();
    setState(() {
      _words = words;
      _isLoading = false;
    });
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    setState(() {
      if (currentIndex != null) {
        _currentIndex = currentIndex;
      }
    });

    // 마지막 카드를 넘긴 경우
    if (currentIndex == null || previousIndex == _words.length - 1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _showCompletionDialog();
      });
    }

    return true; // 스와이프 허용
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학습 완료!'),
        content: Text('${_words.length}개의 단어 학습을 완료했습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('학습하기')),
        body: const Center(
          child: Text('학습할 단어가 없습니다'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('플래시카드 학습'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
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
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _words.length,
            minHeight: 6,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CardSwiper(
                controller: _cardController,
                cardsCount: _words.length,
                numberOfCardsDisplayed: 2,
                onSwipe: _onSwipe,
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  return FlashcardWidget(word: _words[index]);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _cardController.swipe(CardSwiperDirection.left);
                  },
                  icon: const Icon(Icons.close, size: 32),
                  label: const Text('모름'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _cardController.swipe(CardSwiperDirection.right);
                  },
                  icon: const Icon(Icons.check, size: 32),
                  label: const Text('알고있음'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
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
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }
}

class FlashcardWidget extends StatefulWidget {
  final Word word;

  const FlashcardWidget({super.key, required this.word});

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAnswer = !_showAnswer;
        });
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
                  if (!_showAnswer) ...[
                    Text(
                      widget.word.word,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '탭하여 뜻 보기',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ] else ...[
                    Text(
                      widget.word.meaning,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
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
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
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