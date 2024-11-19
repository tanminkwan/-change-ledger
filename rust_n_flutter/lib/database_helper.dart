import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';

Future<String> generate16CharUuid() async {
  final random = Random();
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
}

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  final String dbName;

  // private constructor
  DatabaseHelper._({required this.dbName});

  // factory constructor for instance creation
  factory DatabaseHelper({required String dbName}) {
    _instance ??= DatabaseHelper._(dbName: dbName);
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
  
    print('Initializing database at $path');

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        sender_id TEXT,
        recipient_id TEXT,
        amount REAL,
        timestamp INTEGER,
        signature TEXT,
        prev_hash TEXT,
        current_hash TEXT
      )
    '''
    );
  }

  Future<String> insertData(String senderId, String recipientId, double amount) async {
    final db = await database;

    // 16자리 UUID 생성
    final transactionId = await generate16CharUuid();

    final newTransaction = {
      'transaction_id': transactionId,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'amount': amount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'signature': null,
      'prev_hash': null,
      'current_hash': null,
    };

    await db.insert('transactions', newTransaction, conflictAlgorithm: ConflictAlgorithm.replace);

    // transaction_id 반환
    return transactionId;
  }

  Future<Map<String, dynamic>?> fetchData(String transactionId) async {
    final db = await database;

    // transaction_id를 조건으로 첫 번째 행 조회
    final result = await db.query(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      limit: 1, // 첫 번째 행만 조회
    );

    // 첫 번째 행 반환 (없으면 null 반환)
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateData(int id, String recipientId, double amount) async {
    final db = await database;
    await db.update(
      'transactions',
      {
        'recipient_id': recipientId,
        'amount': amount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'signature': 'updated_signature',
        'prev_hash': 'updated_prev_hash',
        'current_hash': 'updated_current_hash',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteData(int id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}