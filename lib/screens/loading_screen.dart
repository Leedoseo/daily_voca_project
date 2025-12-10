// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// 데이터베이스 서비스
import '../services/database_service.dart';
// 단어 API 서비스
import '../services/word_api_service.dart';
// SharedPreferences 서비스
import '../services/preferences_service.dart';
// SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';
// 메인 화면
import 'main_screen.dart';
// 온보딩 화면
import 'onboarding_screen.dart';

/// 로딩 화면
/// 앱 시작 시 단어 데이터를 로딩하는 화면
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  // 로딩 진행률 (0.0 ~ 1.0)
  double _progress = 0.0;

  // 현재 로딩 중인 단어 개수
  int _loadedCount = 0;

  // 전체 단어 개수
  final int _totalCount = 50;

  // 로딩 메시지
  String _message = '단어 데이터 확인 중...';

  // 에러 발생 여부
  bool _hasError = false;

  // 에러 메시지
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // 화면이 생성되면 바로 초기화 시작
    _initializeApp();
  }

  /// 앱 초기화 (단어 로딩)
  Future<void> _initializeApp() async {
    try {
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

      final dbService = DatabaseService.instance;
      final prefsService = PreferencesService.instance;
      final apiService = WordApiService.instance;

      // SharedPreferences 초기화
      await prefsService.init();

      // 단어 갱신이 필요한지 확인
      if (prefsService.shouldUpdateWords()) {
        setState(() {
          _message = '새로운 단어를 가져오는 중...';
        });

        // 기존 단어 삭제
        await dbService.deleteAllWords();

        // API에서 단어 가져오기 (진행률 콜백 포함)
        final words = await apiService.fetchRandomWords(
          count: _totalCount,
          onProgress: (loaded, total) {
            // 진행률 업데이트
            setState(() {
              _loadedCount = loaded;
              _progress = loaded / total;
              _message = '단어 로딩 중... $_loadedCount/$total';
            });
          },
        );

        // 데이터베이스에 삽입
        setState(() {
          _message = '단어를 저장하는 중...';
        });
        await dbService.initializeWithWords(words);

        // 마지막 갱신 날짜 저장
        await prefsService.setLastWordUpdateDate(prefsService.getTodayDate());

        setState(() {
          _message = '완료!';
          _progress = 1.0;
        });
      } else {
        // 단어 갱신이 필요 없으면 바로 완료
        setState(() {
          _message = '단어 데이터 로드 완료!';
          _progress = 1.0;
        });
      }

      // 잠시 대기 후 메인 화면으로 이동
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // pushReplacement: 현재 화면을 대체 (뒤로가기 시 로딩 화면으로 안 돌아감)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      // 에러 발생 시
      setState(() {
        _hasError = true;
        _errorMessage = '단어를 불러오는 중 오류가 발생했습니다.\n임시 단어로 학습을 시작합니다.';
        _message = '오류 발생';
      });

      // 3초 후 메인 화면으로 이동
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                color: _hasError ? Colors.red : Colors.blue,
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
                _message,
                style: TextStyle(
                  fontSize: 16,
                  color: _hasError ? Colors.red : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 진행률 바
              SizedBox(
                width: 250,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _hasError ? Colors.red : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 진행률 퍼센트 표시
              if (!_hasError)
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              // 에러 메시지
              if (_hasError) ...[
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
                          _errorMessage,
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
  }
}
