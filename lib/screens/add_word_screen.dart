import 'package:flutter/material.dart';
// 단어 모델
import '../models/word.dart';
// Provider
import 'package:provider/provider.dart';
// 단어 관리 Provider
import '../providers/word_provider.dart';

/// 단어 추가 화면
/// 새로운 단어를 입력받아 데이터베이스에 저장
class AddWordScreen extends StatefulWidget {
  const AddWordScreen({super.key});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  // 폼 키: 폼 유효성 검사를 위한 글로벌 키
  final _formKey = GlobalKey<FormState>();

  // 텍스트 입력 컨트롤러
  final _wordController = TextEditingController();
  final _meaningController = TextEditingController();
  final _exampleController = TextEditingController();

  // 저장 중 여부(중복 저장 방지)
  bool _isSaving = false;

  /// 단어 저장 처리
  Future<void> _saveWord() async {
    // 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 중복 저장 방지
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Word 객체 생성 (id는 DB에서 자동 생성되므로 null)
      final word = Word(
        word: _wordController.text.trim(),
        meaning: _meaningController.text.trim(),
        example: _exampleController.text.trim(),
      );

      // Provider를 통해 데이터베이스에 저장
      final wordProvider = Provider.of<WordProvider>(context, listen: false);
      final success = await wordProvider.addWord(word);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('단어가 추가되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          // 이전 화면으로 돌아가기 (true: 목록 새로고침 필요)
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('단어 추가 실패: ${wordProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 추가'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 단어 입력 필드
            TextFormField(
              controller: _wordController,
              decoration: const InputDecoration(
                labelText: '단어',
                hintText: '예: accomplish',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.text_fields),              
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '단어를 입력해주세요';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // 뜻 입력 필드
            TextFormField(
              controller: _meaningController,
              decoration: const InputDecoration(
                labelText: '뜻',
                hintText: '예: 성취하다',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.translate),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '뜻을 입력해주세요';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // 예문 입력 필드 (여러 줄 입력 가능)
            TextFormField(
              controller: _exampleController,
              decoration: const InputDecoration(
                labelText: '예문',
                hintText: '예: She accomplished her goal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat_bubble_outline),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '예문을 입력해주세요';
                }
                return null;
              },
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            // 저장 버튼
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveWord,
              icon: _isSaving
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ) : const Icon(Icons.save),
              label: Text(_isSaving ? '저장중...' : '저장하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 위젯이 제거될 때 컨트롤러 해제 (메모리 누수 방지)
  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    super.dispose();
  }
}