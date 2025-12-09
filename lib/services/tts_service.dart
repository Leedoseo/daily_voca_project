import 'package:flutter_tts/flutter_tts.dart';

/// TTS (Text-To-Speech) 서비스
/// 영어 단어 발음을 재생하는 기능 제공
class TtsService {
  // 싱글톤 패턴
  static final TtsService instance = TtsService._init();
  TtsService._init();

  // FlutterTts 인스턴스
  final FlutterTts _flutterTts = FlutterTts();

  // 초기화 여부
  bool _isInitialized = false;

  /// TTS 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 언어 설정 (영어 - 미국)
      await _flutterTts.setLanguage('en-US');

      // 음성 속도 설정 (0.0 ~ 1.0, 기본값: 0.5)
      await _flutterTts.setSpeechRate(0.5);

      // 음량 설정 (0.0 ~ 1.0, 기본값: 1.0)
      await _flutterTts.setVolume(1.0);

      // 음높이 설정 (0.5 ~ 2.0, 기본값: 1.0)
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
      print('TTS 초기화 완료');
    } catch (e) {
      print('TTS 초기화 실패: $e');
    }
  }

  /// 단어 발음 재생
  Future<void> speak(String word) async {
    try {
      // 초기화되지 않았으면 초기화
      if (!_isInitialized) {
        await initialize();
      }

      // 이미 재생 중이면 중지
      await _flutterTts.stop();

      // 단어 발음 재생
      await _flutterTts.speak(word);
      print('TTS 재생: $word');
    } catch (e) {
      print('TTS 재생 실패: $e');
    }
  }

  /// TTS 중지
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS 중지 실패: $e');
    }
  }

  /// TTS 리소스 해제
  void dispose() {
    _flutterTts.stop();
  }
}
