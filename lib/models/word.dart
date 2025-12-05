/// 단어 모델 클래스
/// 데이터베이스의 words 테이블과 매핑되는 객체
class Word {
  // 데이터베이스 ID (자동 증가, 새로 생성할 때는 null)
  // int?: nullable 타입 (null일 수 있음)
  final int? id;

  // 영어 단어
  final String word;

  // 한글 뜻
  final String meaning;

  // 예문
  final String example;

  /// 생성자
  /// required: 필수 매개변수 (반드시 값을 전달해야 함)
  Word({
    this.id,
    required this.word,
    required this.meaning,
    required this.example,
  });

  /// Word 객체를 Map으로 변환 (데이터베이스에 저장할 때 사용)
  /// 반환값: {'id': 1, 'word': 'example', 'meaning': '예시', 'example': '...'}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'example': example,
    };
  }

  /// Map을 Word 객체로 변환 (데이터베이스에서 읽어올 때 사용)
  /// factory: 생성자의 특별한 형태, 인스턴스를 반환
  /// as int?: int 타입으로 캐스팅, null 허용
  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int?,
      word: map['word'] as String,
      meaning: map['meaning'] as String,
      example: map['example'] as String,
    );
  }
}
