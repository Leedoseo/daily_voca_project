// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// 데이터베이스 서비스
import '../services/database_service.dart';
// 날짜 포맷팅
import 'package:intl/intl.dart';
// 학습 기록 상세 화면
import 'study_record_detail_screen.dart';

/// 학습 기록 히스토리 화면
/// 날짜별 학습 기록 목록을 표시
class StudyHistoryScreen extends StatefulWidget {
  const StudyHistoryScreen({super.key});

  @override
  State<StudyHistoryScreen> createState() => _StudyHistoryScreenState();
}

class _StudyHistoryScreenState extends State<StudyHistoryScreen> {
  final DatabaseService _dbService = DatabaseService.instance;

  // 로딩 상태
  bool _isLoading = true;

  // 날짜별 학습 기록 목록
  List<Map<String, dynamic>> _studyDates = [];

  @override
  void initState() {
    super.initState();
    _loadStudyDates();
  }

  /// 학습 기록 날짜 목록 로드
  Future<void> _loadStudyDates() async {
    setState(() => _isLoading = true);

    try {
      final dates = await _dbService.getStudyDates();
      setState(() {
        _studyDates = dates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _studyDates = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학습 기록'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studyDates.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _studyDates.length,
                  itemBuilder: (context, index) {
                    final dateRecord = _studyDates[index];
                    return _buildDateCard(dateRecord);
                  },
                ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '학습 기록이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '단어를 학습하면 여기에 기록이 표시됩니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 날짜별 학습 기록 카드
  Widget _buildDateCard(Map<String, dynamic> dateRecord) {
    final dateString = dateRecord['date'] as String;
    final totalStudied = dateRecord['totalStudied'] as int;
    final correctCount = dateRecord['correctCount'] as int;
    final incorrectCount = dateRecord['incorrectCount'] as int;
    final accuracy =
        totalStudied > 0 ? (correctCount / totalStudied * 100) : 0.0;

    // 날짜 포맷팅
    final date = DateTime.parse(dateString);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    String displayDate;
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      displayDate = '오늘';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      displayDate = '어제';
    } else {
      displayDate = DateFormat('MM월 dd일 (E)', 'ko_KR').format(date);
    }

    final fullDate = DateFormat('yyyy년 MM월 dd일').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // 상세 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyRecordDetailScreen(date: dateString),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 헤더
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayDate,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          fullDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 통계 요약
              Row(
                children: [
                  _buildStatChip('학습 ${totalStudied}개', Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatChip('맞힘 $correctCount', Colors.green),
                  const SizedBox(width: 8),
                  _buildStatChip('틀림 $incorrectCount', Colors.red),
                ],
              ),
              const SizedBox(height: 12),

              // 정확도 진행바
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '정확도',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${accuracy.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: accuracy / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        accuracy >= 80
                            ? Colors.green
                            : accuracy >= 50
                                ? Colors.orange
                                : Colors.red,
                      ),
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

  /// 통계 칩 위젯
  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
