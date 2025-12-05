class StudyRecord {
  final int? id;
  final String date;
  final int wordId;
  final bool result; // true: 알고있음, false: 모름

  StudyRecord({
    this.id,
    required this.date,
    required this.wordId,
    required this.result,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'word_id': wordId,
      'result': result ? 1 : 0,
    };
  }

  factory StudyRecord.fromMap(Map<String, dynamic> map) {
    return StudyRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      wordId: map['word_id'] as int,
      result: map['result'] == 1,
    );
  }
}
