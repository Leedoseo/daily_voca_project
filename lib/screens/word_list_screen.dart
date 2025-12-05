// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// 단어 모델
import '../models/word.dart';
// 데이터베이스 서비스
import '../services/database_service.dart';
// 단어 상세 화면
import 'word_detail_screen.dart';

/// 단어 목록 화면
/// 모든 단어를 보여주고 검색할 수 있는 화면
class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

/// WordListScreen의 상태 관리 클래스
class _WordListScreenState extends State<WordListScreen> {
  // 데이터베이스 서비스
  final DatabaseService _dbService = DatabaseService.instance;

  // 전체 단어 목록
  List<Word> _words = [];

  // 검색 필터링된 단어 목록 (화면에 실제로 표시되는 목록)
  List<Word> _filteredWords = [];

  // 로딩 중 여부
  bool _isLoading = true;

  // 검색 입력 필드의 텍스트를 제어하는 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  /// 데이터베이스에서 모든 단어 로드
  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    final words = await _dbService.getAllWords();
    setState(() {
      _words = words; // 전체 목록
      _filteredWords = words; // 초기에는 필터링 안 함
      _isLoading = false;
    });
  }

  /// 검색어로 단어 필터링
  /// query: 사용자가 입력한 검색어
  void _filterWords(String query) {
    setState(() {
      if (query.isEmpty) {
        // 검색어가 없으면 전체 목록 표시
        _filteredWords = _words;
      } else {
        // where(): 조건에 맞는 요소만 필터링
        // toLowerCase(): 대소문자 구분 없이 검색
        // contains(): 문자열 포함 여부 확인
        _filteredWords = _words
            .where((word) =>
                word.word.toLowerCase().contains(query.toLowerCase()) ||
                word.meaning.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 목록'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterWords,
              decoration: InputDecoration(
                hintText: '단어 검색...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredWords.isEmpty
              ? const Center(
                  child: Text(
                    '단어가 없습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredWords.length,
                  itemBuilder: (context, index) {
                    final word = _filteredWords[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(
                          word.word,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          word.meaning,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordDetailScreen(word: word),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}