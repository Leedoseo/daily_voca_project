class Word {
  final int? id;
  final String word;
  final String meaning;
  final String example;

  Word({
    this.id,
    required this.word,
    required this.meaning,
    required this.example,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'example': example,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int?,
      word: map['word'] as String,
      meaning: map['meaning'] as String,
      example: map['example'] as String,
    );
  }
}
