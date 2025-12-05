import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';
import '../models/study_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('daily_voca.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // words 테이블 생성
    await db.execute('''
      CREATE TABLE words (
        id $idType,
        word $textType,
        meaning $textType,
        example $textType
      )
    ''');

    // study_records 테이블 생성
    await db.execute('''
      CREATE TABLE study_records (
        id $idType,
        date $textType,
        word_id $intType,
        result $intType,
        FOREIGN KEY (word_id) REFERENCES words (id)
      )
    ''');
  }

  // Words CRUD
  Future<int> insertWord(Word word) async {
    final db = await database;
    return await db.insert('words', word.toMap());
  }

  Future<List<Word>> getAllWords() async {
    final db = await database;
    final result = await db.query('words');
    return result.map((map) => Word.fromMap(map)).toList();
  }

  Future<Word?> getWord(int id) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Word.fromMap(maps.first);
    }
    return null;
  }

  // Study Records CRUD
  Future<int> insertStudyRecord(StudyRecord record) async {
    final db = await database;
    return await db.insert('study_records', record.toMap());
  }

  Future<List<StudyRecord>> getStudyRecordsByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'study_records',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((map) => StudyRecord.fromMap(map)).toList();
  }

  Future<List<StudyRecord>> getAllStudyRecords() async {
    final db = await database;
    final result = await db.query('study_records');
    return result.map((map) => StudyRecord.fromMap(map)).toList();
  }

  // 유틸리티
  Future<void> deleteAllWords() async {
    final db = await database;
    await db.delete('words');
  }

  Future<void> deleteAllStudyRecords() async {
    final db = await database;
    await db.delete('study_records');
  }

  Future<int> getWordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> initializeWithWords(List<Word> words) async {
    final db = await database;
    final batch = db.batch();

    for (var word in words) {
      batch.insert('words', word.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
