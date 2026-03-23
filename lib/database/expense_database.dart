import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';

class ExpenseDatabase {
  ExpenseDatabase._internal();
  static final ExpenseDatabase instance = ExpenseDatabase._internal();

  static Database? _database;

  // 🔐 Current Firebase user UID
  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user.uid;
  }

  // 🗄️ User-specific table
  String get _tableName => 'expenses_$_uid';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses.db');

    return await openDatabase(path, version: 1);
  }

  // ✅ Create table ONLY if it does not exist
  Future<void> _ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        paymentMethod TEXT NOT NULL,
        location TEXT
      )
    ''');
  }

  // ================= CRUD =================

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    await _ensureTable(db);

    final result = await db.query(
      _tableName,
      orderBy: 'date DESC',
    );

    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await _ensureTable(db);
    await db.insert(_tableName, expense.toMap());
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await _ensureTable(db);

    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}