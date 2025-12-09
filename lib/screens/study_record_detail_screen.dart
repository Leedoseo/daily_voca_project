// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// 데이터베이스 서비스
import '../services/database_service.dart';
// 날짜 포맷팅
import 'package:intl/intl.dart';

/// 학습 기록 상세 화면
/// 특정 날짜의 학습한 단어 목록과 결과를 표시
class StudyRecordDetailScreen extends StatefulWidget {
  // 조회할 날짜 (yyyy-MM-dd 형식)
  final String date;

  const StudyRecordDetailScreen({super.key, required this.date});

  @override
  State<StudyRecordDetailScreen> createState() =>
      _StudyRecordDetailScreenState();
}

class _StudyRecordDetailScreenState extends State<StudyRecordDetailScreen> {
  final DatabaseService _dbService = DatabaseService.instance;

  // 로딩 상태
  bool _isLoading = true;

  // 학습 기록 목록 (단어 정보 포함)
  List<Map<String, dynamic>> _records = [];

  // 통계 데이터
  int _totalStudied = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  /// 학습 기록 로드
  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      // 학습 기록과 단어 정보 함께 조회
      final records =
          await _dbService.getStudyRecordsWithWordsByDate(widget.date);

      // 통계 조회
      final stats = await _dbService.getStudyStatisticsByDate(widget.date);

      setState(() {
        _records = records;
        _totalStudied = stats['totalStudied'] ?? 0;
        _correctCount = stats['correctCount'] ?? 0;
        _incorrectCount = stats['incorrectCount'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _records = [];
        _totalStudied = 0;
        _correctCount = 0;
        _incorrectCount = 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 날짜 포맷팅 (2024-12-09 -> 2024년 12월 09일)
    final formattedDate = DateFormat('yyyy년 MM월 dd일').format(
      DateTime.parse(widget.date),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(formattedDate),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // 상단 통계 요약
                    _buildStatisticsSummary(),
                    const Divider(height: 1),
                    // 학습 기록 목록
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          return _buildRecordCard(record);
                        },
                      ),
                    ),
                  ],
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
            Icons.history_edu,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '이 날의 학습 기록이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 통계 요약 위젯
  Widget _buildStatisticsSummary() {
    final accuracy =
        _totalStudied > 0 ? (_correctCount / _totalStudied * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('총 학습', _totalStudied.toString(), Colors.blue),
          _buildStatItem('맞힘', _correctCount.toString(), Colors.green),
          _buildStatItem('틀림', _incorrectCount.toString(), Colors.red),
          _buildStatItem('정확도', '${accuracy.toStringAsFixed(0)}%',
              Colors.orange),
        ],
      ),
    );
  }

  /// 통계 항목 위젯
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
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
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// 학습 기록 카드 위젯
  Widget _buildRecordCard(Map<String, dynamic> record) {
    final word = record['word'] as String;
    final meaning = record['meaning'] as String;
    final example = record['example'] as String;
    final result = record['result'] == 1; // 1: 맞음, 0: 틀림

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: result ? Colors.green.shade200 : Colors.red.shade200,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 단어와 결과 아이콘
            Row(
              children: [
                // 결과 아이콘
                Icon(
                  result ? Icons.check_circle : Icons.cancel,
                  color: result ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                // 단어
                Expanded(
                  child: Text(
                    word,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 뜻
            Text(
              meaning,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            // 예문
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                example,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
