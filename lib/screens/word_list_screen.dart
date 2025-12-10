// Flutter Material Design 위젯
import 'package:flutter/material.dart';
// 단어 모델
import '../models/word.dart';
// 데이터베이스 서비스
import '../services/database_service.dart';
// 단어 상세 화면
import 'word_detail_screen.dart';
// 단어 추가 화면 추가
import 'add_word_screen.dart';

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

  /// 단어 삭제 처리 (새로 추가)
  Future<void> _deleteWord(Word word) async {
    // 삭제 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단어 삭제'),
        content: Text('\'${word.word}\'를 삭제하시겠습니까?'),
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
    if (confirmed == true) {
      try {
        await _dbService.deleteWord(word.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('단어가 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          // 목록 새로고침
          _loadWords();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
      // FloatingActionButton 추가
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 단어 추가 화면으로 이동
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddWordScreen(),
            ),
          );
          // 단어가 추가되었으면 목록 새로고침
          if (result == true) {
            _loadWords();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredWords.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _filteredWords.length,
                  itemBuilder: (context, index) {
                    final word = _filteredWords[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      // Dismissible로 감싸서 스와이프 삭제 기능 추가
                      child: Dismissible(
                        key: Key(word.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          // 스와이프 시 삭제 확인 다이얼로그 표시
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('단어 삭제'),
                              content: Text('\'${word.word}\'를 삭제하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('삭제',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          // 삭제 실행
                          try {
                            await _dbService.deleteWord(word.id!);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('단어가 삭제되었습니다'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadWords();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('삭제 실패: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              _loadWords();
                            }
                          }
                        },
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 삭제 버튼 추가
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteWord(word),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () async {
                            // 상세 화면으로 이동
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WordDetailScreen(word: word),
                              ),
                            );
                            // 수정 또는 삭제되었으면 목록 새로고침
                            if (result == true) {
                              _loadWords();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    // 검색어가 있으면 검색 결과 없음, 없으면 단어 목록 비어있음
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.book_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? '검색 결과가 없습니다' : '단어가 없습니다',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? '다른 검색어로 시도해보세요'
                  : '우측 하단 + 버튼을 눌러\n첫 번째 단어를 추가해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddWordScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadWords();
                  }
                },
                icon: const Icon(Icons.add, size: 28),
                label: const Text(
                  '단어 추가하기',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}