import 'package:flutter/material.dart';
// 단어 모델
import '../models/word.dart';
// DB서비스
import '../services/database_service.dart';

/// 단어 수정 화면
/// 기존 단어 정보를 불러와서 수정
class EditWordScreen extends StatefulWidget {
  final Word word;

  const EditWordScreen({super.key, required this.word});

  @override
  State<EditWordScreen> createState() => _EditWordScreenState();
}

class _EditWordScreenState extends State<EditWordScreen> {
  // 폼 키: 폼 유효성 검사를 위한 글로벌 키
  final _formKey = GlobalKey<FormState>();

  // 텍스트 입력 컨트롤러
  late final TextEditingController _wordController;
  late final TextEditingController _meaningController;
  late final TextEditingController _exampleController;

  // DB 서비스
  final DatabaseService _dbService = DatabaseService.instance;

  // 저장 중 여부(중복 저장 방지)
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 기존 단어 정보로 컨트롤러 초기화
    _wordController = TextEditingController(text: widget.word.word);
    _meaningController = TextEditingController(text: widget.word.meaning);
    _exampleController = TextEditingController(text: widget.word.example);
  }

  /// 단어 수정 처리
  Future<void> _updateWord() async {
    // 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 중복 저장 방지
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Word 객체 생성 (기존 id 유지)
      final updatedWord = Word(
        id: widget.word.id,
        word: _wordController.text.trim(),
        meaning: _meaningController.text.trim(),
        example: _exampleController.text.trim(),
      );

      // 데이터베이스에 업데이트
      await _dbService.updateWord(updatedWord);

      // 저장 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('단어가 수정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // 이전 화면으로 돌아가기 (true: 목록 새로고침 필요)
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // 저장 실패 시 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단어 수정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        title: const Text('단어 수정'),
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
              onPressed: _isSaving ? null : _updateWord,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? '수정 중...' : '수정하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
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
