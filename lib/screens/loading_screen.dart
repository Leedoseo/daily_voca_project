// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';
// 메인 화면
import 'main_screen.dart';
// 온보딩 화면
import 'onboarding_screen.dart';
// Provider
import 'package:provider/provider.dart';
// 단어 관리 Provider
import '../providers/word_provider.dart';

/// 로딩 화면
/// 앱 시작 시 단어 데이터를 로딩하는 화면
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 생성되면 바로 초기화 시작
    _initializeApp();
  }

  /// 앱 초기화 (단어 로딩)
  Future<void> _initializeApp() async {
    // 첫 실행 확인
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    // 첫 실행이면 온보딩 화면으로 이동
    if (isFirstLaunch) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
      return;
    }

    // WordProvider를 사용하여 단어 로드
    final wordProvider = Provider.of<WordProvider>(context, listen: false);
    await wordProvider.loadWords();

    // 잠시 대기 후 메인 화면으로 이동
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WordProvider>(
      builder: (context, wordProvider, child) {
        return Scaffold(
          backgroundColor: Colors.blue.shade50,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 앱 아이콘
                  Icon(
                    Icons.school,
                    size: 100,
                    color: wordProvider.hasError ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(height: 32),

                  // 앱 제목
                  const Text(
                    'Daily Voca',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 로딩 메시지
                  Text(
                    wordProvider.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: wordProvider.hasError ? Colors.red : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // 진행률 바
                  SizedBox(
                    width: 250,
                    child: LinearProgressIndicator(
                      value: wordProvider.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        wordProvider.hasError ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 진행률 퍼센트 표시
                  if (!wordProvider.hasError)
                    Text(
                      '${(wordProvider.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  // 에러 메시지
                  if (wordProvider.hasError) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              wordProvider.errorMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
