import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/database_service.dart';
import 'word_detail_screen.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  List<Word> _words = [];
  List<Word> _filteredWords = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

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
      _filteredWords = words;
      _isLoading = false;
    });
  }

  void _filterWords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWords = _words;
      } else {
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