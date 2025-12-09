// SQLite 데이터베이스 패키지
import 'package:sqflite/sqflite.dart';
// 파일 경로 조작을 위한 패키지 (join 함수 사용)
import 'package:path/path.dart';
// 단어 모델
import '../models/word.dart';
// 학습 기록 모델
import '../models/study_record.dart';

/// 데이터베이스 서비스 클래스
/// SQLite 데이터베이스의 모든 작업을 관리
class DatabaseService {
  // 싱글톤 패턴: 앱 전체에서 하나의 인스턴스만 사용
  // static: 클래스 레벨 변수 (객체 생성 없이 접근 가능)
  // final: 한 번 할당되면 변경 불가
  static final DatabaseService instance = DatabaseService._init();

  // 데이터베이스 객체를 저장하는 변수
  // ?: nullable 타입 (null일 수 있음)
  static Database? _database;

  // private 생성자 (_로 시작하면 private)
  // 외부에서 new DatabaseService() 불가능 -> 싱글톤 보장
  DatabaseService._init();

  /// 데이터베이스 인스턴스를 반환하는 getter
  /// 처음 호출 시 데이터베이스 생성, 이후에는 기존 인스턴스 반환
  Future<Database> get database async {
    // 이미 데이터베이스가 있으면 반환
    if (_database != null) return _database!; // !: null이 아님을 확신
    // 없으면 초기화
    _database = await _initDB('daily_voca.db');
    return _database!;
  }

  /// 데이터베이스 파일을 초기화하고 열기
  Future<Database> _initDB(String filePath) async {
    // 데이터베이스를 저장할 디렉토리 경로 가져오기
    // iOS: Library/Application Support/, Android: /data/data/<package>/databases/
    final dbPath = await getDatabasesPath();

    // 디렉토리 경로 + 파일명 결합
    // 예: /data/data/com.example.app/databases/daily_voca.db
    final path = join(dbPath, filePath);

    // 데이터베이스 열기 (없으면 생성)
    return await openDatabase(
      path,
      version: 2, // 데이터베이스 버전 (스키마 변경 시 증가)
      onCreate: _createDB, // 처음 생성될 때 호출될 함수
      onUpgrade: _upgradeDB, // 버전 업그레이드 시 호출될 함수
    );
  }

  /// 데이터베이스 테이블 생성
  /// 처음 데이터베이스가 만들어질 때 한 번만 실행됨
  Future<void> _createDB(Database db, int version) async {
    // SQL 데이터 타입 정의
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT'; // 자동 증가 ID
    const textType = 'TEXT NOT NULL'; // 필수 텍스트
    const intType = 'INTEGER NOT NULL'; // 필수 정수

    // words 테이블 생성: 단어 정보 저장
    await db.execute('''
      CREATE TABLE words (
        id $idType,
        word $textType,
        meaning $textType,
        example $textType
      )
    ''');

    // study_records 테이블 생성: 학습 기록 저장
    await db.execute('''
      CREATE TABLE study_records (
        id $idType,
        date $textType,
        word_id $intType,
        result $intType,
        is_review $intType DEFAULT 0,
        FOREIGN KEY (word_id) REFERENCES words (id)
      )
    ''');
  }

  /// 데이터베이스 업그레이드
  /// 버전이 올라갈 때 기존 데이터를 유지하면서 스키마 변경
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 버전 1 -> 2: study_records 테이블에 is_review 컬럼 추가
      await db.execute('''
        ALTER TABLE study_records ADD COLUMN is_review INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }

  /// Words CRUD
  /// 단어 추가
  /// 반환값: 삽입된 행의 ID
  Future<int> insertWord(Word word) async {
    try {
      final db = await database;
      // word.toMap(): Word 객체를 Map으로 변환 (SQL INSERT에 필요)
      return await db.insert('words', word.toMap());
    } catch (e) {
      throw Exception('단어 추가 실패: $e');
    }
  }

  /// 모든 단어 조회
  /// 반환값: Word 객체 리스트
  Future<List<Word>> getAllWords() async {
    try {
      final db = await database;
      // SELECT * FROM words
      final result = await db.query('words');
      // Map 리스트를 Word 객체 리스트로 변환
      // map(): 각 요소를 변환, toList(): 결과를 List로
      return result.map((map) => Word.fromMap(map)).toList();
    } catch (e) {
      throw Exception('단어 목록 조회 실패: $e');
    }
  }

  /// 특정 ID의 단어 조회
  /// 반환값: Word 객체 또는 null (없으면)
  Future<Word?> getWord(int id) async {
    final db = await database;
    // SELECT * FROM words WHERE id = ?
    // where: 조건, whereArgs: ? 부분에 들어갈 값 (SQL Injection 방지)
    final maps = await db.query('words', where: 'id = ?', whereArgs: [id]);

    // 결과가 있으면 첫 번째 행을 Word 객체로 변환
    if (maps.isNotEmpty) {
      return Word.fromMap(maps.first);
    }
    return null; // 결과 없음
  }

  /// 단어 수정
  Future<int> updateWord(Word word) async {
    try {
      final db = await database;
      // UPDATE words SET ... WHERE id = ?
      return await db.update('words', word.toMap(),
          where: 'id = ?', whereArgs: [word.id]);
    } catch (e) {
      throw Exception('단어 수정 실패: $e');
    }
  }

  /// 특정 단어 삭제
  Future<int> deleteWord(int id) async {
    try {
      final db = await database;
      // DELETE FROM words WHERE id = ?
      return await db.delete('words', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('단어 삭제 실패: $e');
    }
  }

  /// 틀린 단어 목록 조회 (복습용)
  /// 가장 최근 학습 기록에서 result = 0 (모름)인 단어들을 반환
  /// 복습에서 맞춘 단어는 제외됨
  Future<List<Word>> getIncorrectWords() async {
    try {
      final db = await database;
      // 서브쿼리를 사용하여 각 단어의 가장 최근 학습 기록만 조회
      // MAX(sr.id): 같은 단어에 대한 여러 기록 중 가장 최근 것 (id가 클수록 최근)
      final result = await db.rawQuery('''
        SELECT DISTINCT w.*
        FROM words w
        INNER JOIN study_records sr ON w.id = sr.word_id
        WHERE sr.id IN (
          SELECT MAX(id)
          FROM study_records
          GROUP BY word_id
        )
        AND sr.result = 0
        ORDER BY sr.date DESC
      ''');

      // Map 리스트를 Word 객체 리스트로 변환
      return result.map((map) => Word.fromMap(map)).toList();
    } catch (e) {
      throw Exception('복습 단어 조회 실패: $e');
    }
  }

  /// 틀린 단어 개수 조회 (복습용)
  /// 가장 최근 학습 기록 기준으로 틀린 단어 개수만 반환
  Future<int> getIncorrectWordsCount() async {
    try {
      final db = await database;
      // 서브쿼리를 사용하여 각 단어의 가장 최근 학습 기록만 카운트
      final result = await db.rawQuery('''
        SELECT COUNT(DISTINCT w.id) as count
        FROM words w
        INNER JOIN study_records sr ON w.id = sr.word_id
        WHERE sr.id IN (
          SELECT MAX(id)
          FROM study_records
          GROUP BY word_id
        )
        AND sr.result = 0
      ''');

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('복습 단어 개수 조회 실패: $e');
    }
  }

  /// Study Records CRUD
  /// 학습 기록 추가
  /// 반환값: 삽입된 행의 ID
  Future<int> insertStudyRecord(StudyRecord record) async {
    try {
      final db = await database;
      return await db.insert('study_records', record.toMap());
    } catch (e) {
      throw Exception('학습 기록 추가 실패: $e');
    }
  }

  /// 학습 기록 삭제 (Undo 기능용)
  /// id: 삭제할 학습 기록의 ID
  /// 반환값: 삭제된 행의 개수
  Future<int> deleteStudyRecord(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'study_records',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('학습 기록 삭제 실패: $e');
    }
  }

  /// 특정 날짜의 학습 기록 조회 (복습 제외)
  /// 예: '2024-12-05'
  Future<List<StudyRecord>> getStudyRecordsByDate(String date) async {
    try {
      final db = await database;
      // SELECT * FROM study_records WHERE date = ? AND is_review = 0
      final result = await db.query(
        'study_records',
        where: 'date = ? AND is_review = 0',
        whereArgs: [date],
      );
      return result.map((map) => StudyRecord.fromMap(map)).toList();
    } catch (e) {
      throw Exception('학습 기록 조회 실패: $e');
    }
  }

  /// 특정 날짜의 학습 기록을 단어 정보와 함께 조회 (복습 제외)
  /// 반환값: List<Map> - 각 Map은 학습 기록 + 단어 정보
  Future<List<Map<String, dynamic>>> getStudyRecordsWithWordsByDate(
      String date) async {
    try {
      final db = await database;
      // JOIN으로 학습 기록과 단어 정보를 함께 조회
      final result = await db.rawQuery('''
        SELECT
          sr.id as record_id,
          sr.date,
          sr.result,
          sr.is_review,
          w.id as word_id,
          w.word,
          w.meaning,
          w.example
        FROM study_records sr
        INNER JOIN words w ON sr.word_id = w.id
        WHERE sr.date = ? AND sr.is_review = 0
        ORDER BY sr.id DESC
      ''', [date]);

      return result;
    } catch (e) {
      throw Exception('학습 기록 상세 조회 실패: $e');
    }
  }

  /// 특정 날짜의 학습 통계 조회 (고유 단어 기준, 복습 제외)
  /// 반환값: {totalStudied, correctCount, incorrectCount}
  Future<Map<String, int>> getStudyStatisticsByDate(String date) async {
    try {
      final db = await database;

      // 각 단어의 가장 최근 학습 기록만 사용하여 통계 계산
      // 같은 날 여러 번 학습한 단어는 마지막 결과만 반영
      final result = await db.rawQuery('''
        SELECT
          COUNT(*) as total,
          SUM(CASE WHEN result = 1 THEN 1 ELSE 0 END) as correct,
          SUM(CASE WHEN result = 0 THEN 1 ELSE 0 END) as incorrect
        FROM study_records
        WHERE id IN (
          SELECT MAX(id)
          FROM study_records
          WHERE date = ? AND is_review = 0
          GROUP BY word_id
        )
      ''', [date]);

      if (result.isEmpty) {
        return {'totalStudied': 0, 'correctCount': 0, 'incorrectCount': 0};
      }

      final row = result.first;
      return {
        'totalStudied': (row['total'] as int?) ?? 0,
        'correctCount': (row['correct'] as int?) ?? 0,
        'incorrectCount': (row['incorrect'] as int?) ?? 0,
      };
    } catch (e) {
      throw Exception('학습 통계 조회 실패: $e');
    }
  }

  /// 모든 학습 기록 조회 (복습 제외)
  Future<List<StudyRecord>> getAllStudyRecords() async {
    try {
      final db = await database;
      // is_review = 0인 것만 조회 (일반 학습만)
      final result = await db.query(
        'study_records',
        where: 'is_review = 0',
      );
      return result.map((map) => StudyRecord.fromMap(map)).toList();
    } catch (e) {
      throw Exception('학습 기록 조회 실패: $e');
    }
  }

  /// 학습 기록이 있는 날짜 목록 조회 (복습 제외, 최신순)
  /// 반환값: List<Map> - 각 Map은 {date, totalStudied, correctCount, incorrectCount}
  Future<List<Map<String, dynamic>>> getStudyDates() async {
    try {
      final db = await database;
      // 날짜별로 그룹화하여 통계와 함께 조회
      // 각 단어의 가장 최근 학습 기록만 사용 (고유 단어 기준)
      final result = await db.rawQuery('''
        SELECT
          date,
          COUNT(*) as total_studied,
          SUM(CASE WHEN result = 1 THEN 1 ELSE 0 END) as correct_count,
          SUM(CASE WHEN result = 0 THEN 1 ELSE 0 END) as incorrect_count
        FROM study_records
        WHERE id IN (
          SELECT MAX(id)
          FROM study_records
          WHERE is_review = 0
          GROUP BY date, word_id
        )
        GROUP BY date
        ORDER BY date DESC
      ''');

      return result.map((row) {
        return {
          'date': row['date'] as String,
          'totalStudied': (row['total_studied'] as int?) ?? 0,
          'correctCount': (row['correct_count'] as int?) ?? 0,
          'incorrectCount': (row['incorrect_count'] as int?) ?? 0,
        };
      }).toList();
    } catch (e) {
      throw Exception('학습 날짜 목록 조회 실패: $e');
    }
  }

  // 유틸리티
  /// 모든 단어 삭제 (테스트용)
  Future<void> deleteAllWords() async {
    final db = await database;
    // DELETE FROM words
    await db.delete('words');
  }

  /// 모든 학습 기록 삭제 (테스트용)
  Future<void> deleteAllStudyRecords() async {
    final db = await database;
    await db.delete('study_records');
  }

  /// 단어 개수 조회
  /// 반환값: 저장된 단어의 개수
  Future<int> getWordCount() async {
    final db = await database;
    // SQL 직접 실행: SELECT COUNT(*) as count FROM words
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    // 첫 번째 정수 값 추출, null이면 0 반환
    // ??: null이면 오른쪽 값 사용 (null 병합 연산자)
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 여러 단어를 한 번에 삽입 (초기 데이터용)
  /// Batch: 여러 작업을 모아서 한 번에 실행 (성능 향상)
  Future<void> initializeWithWords(List<Word> words) async {
    final db = await database;
    // 배치 작업 시작
    final batch = db.batch();

    // 모든 단어를 배치에 추가
    for (var word in words) {
      batch.insert('words', word.toMap());
    }

    // 배치 실행 (모든 INSERT를 한 번에 수행)
    // noResult: 결과 반환하지 않음 (더 빠름)
    await batch.commit(noResult: true);
  }

  /// 데이터베이스 연결 종료
  /// 앱 종료 시 호출
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
