import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

  Future<void> insertData(String senderId, String recipientId, double amount) async {
    final db = await database;
    final newTransaction = {
      'transaction_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender_id': senderId,
      'recipient_id': recipientId,
      'amount': amount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'signature': null,
      'prev_hash': null,
      'current_hash': null,
    };
    await db.insert('transactions', newTransaction, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    final db = await database;
    return await db.query('transactions');
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