import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loading_screen.dart';

/// 첫 실행 시 나타나는 온보딩 화면
/// 일일 학습 목표를 설정합니다
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _selectedGoal = 50; // 기본값 50개

  // 일반적인 목표 선택지
  final List<int> _goalOptions = [20, 30, 40, 50, 60, 80, 100];

  /// 목표 설정 후 앱으로 진입
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    // 일일 목표 저장
    await prefs.setInt('daily_goal', _selectedGoal);

    // 첫 실행 완료 플래그 저장
    await prefs.setBool('is_first_launch', false);

    if (mounted) {
      // LoadingScreen으로 이동 (replace - 뒤로가기 불가)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoadingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // 환영 메시지
              Icon(
                Icons.book_outlined,
                size: 100,
                color: Colors.blue.shade400,
              ),
              const SizedBox(height: 32),
              Text(
                'Daily Voca에\n오신 것을 환영합니다!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                '매일 학습할 단어 수를 설정해주세요.\n나중에 설정에서 변경할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // 목표 설정 카드
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        '일일 학습 목표',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // 선택된 목표 표시
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_selectedGoal',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '개',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 목표 선택 버튼들
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _goalOptions.map((goal) {
                          final isSelected = goal == _selectedGoal;
                          return ChoiceChip(
                            label: Text('$goal개'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedGoal = goal;
                              });
                            },
                            selectedColor: Colors.blue.shade300,
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // 시작하기 버튼
              ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
