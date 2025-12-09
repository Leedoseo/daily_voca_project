/// 학습 기록 모델 클래스
/// 데이터베이스의 study_records 테이블과 매핑되는 객체
class StudyRecord {
  // 데이터베이스 ID (자동 증가)
  final int? id;

  // 학습 날짜 (형식: 'YYYY-MM-DD', 예: '2024-12-05')
  final String date;

  // 학습한 단어의 ID (words 테이블의 id 참조)
  // FOREIGN KEY: 외래 키 - 다른 테이블의 기본 키를 참조
  final int wordId;

  // 학습 결과 (true: 알고있음, false: 모름)
  final bool result;

  // 복습 모드 여부 (true: 복습, false: 일반 학습)
  final bool isReview;

  /// 생성자
  StudyRecord({
    this.id,
    required this.date,
    required this.wordId,
    required this.result,
    this.isReview = false, // 기본값: 일반 학습
  });

  /// StudyRecord 객체를 Map으로 변환 (데이터베이스에 저장할 때 사용)
  /// SQLite는 boolean 타입이 없어서 정수로 변환 (1: true, 0: false)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'word_id': wordId, // 데이터베이스 컬럼명은 snake_case
      'result': result ? 1 : 0, // bool → int 변환 (삼항 연산자)
      'is_review': isReview ? 1 : 0, // 복습 여부
    };
  }

  /// Map을 StudyRecord 객체로 변환 (데이터베이스에서 읽어올 때 사용)
  /// factory: 생성자의 특별한 형태
  factory StudyRecord.fromMap(Map<String, dynamic> map) {
    return StudyRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      wordId: map['word_id'] as int, // 데이터베이스 컬럼명
      result: map['result'] == 1, // int → bool 변환 (1이면 true)
      isReview: map['is_review'] == 1, // 복습 여부
    );
  }
}
