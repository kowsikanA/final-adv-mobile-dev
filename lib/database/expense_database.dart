// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';

// import '../models/expense.dart';

// class ExpenseDatabase {
//   static final ExpenseDatabase instance = ExpenseDatabase._init();
//   ExpenseDatabase._init();

//   static Database? _database;

//   Future <Database> get database async{
//     if (_database != null ) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }

//   // initialize database
//   Future <Database> _initDatabase() async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, 'expenseDatabase.db');

//     return await openDatabase(
//       path, 
//       version: 1,
//       onCreate: (db, version) async{
//         await db.execute('''
//                           CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, 
//                           title TEXT NOT NULL ,  
//                           amount REAL NOT NULL, 
//                           category TEXT NOT NULL,
//                           date TEXT,
//                           description TEXT, 
//                           paymentMethod TEXT NOT NULL
//                           )
//                           ''');
    
//       },
//     );
//   }

//   // adding expense
//   Future <int> insertExpense(Expense expense) async {
//     final db = await database;
//     return await db.insert(
//       'expenses', 
//       expense.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace);
//   }

//   // getting all expenses
//   Future <List<Expense>> getExpenses() async {
//     final db = await database;

//     final List<Map<String, dynamic>> maps = await db.query(
//       'expenses',
//       orderBy: 'date DESC' // order by last added
//     );

//     List <Expense> expenses = [];

//     if (maps.length > 0){
//       for(int i = 0; i < maps.length; i++){
//         expenses.add(Expense.fromMap(maps[i]));
//       }
//     }

//     return expenses;
//   }

//   // getting all expenses
//   Future <Expense?> getExpensesByID(int id) async {
//     final db = await database;

//     final  maps = await db.query(
//       'expenses',
//       where: 'id=?',
//       whereArgs: [id],
//       limit: 1,
//     );

//     if (maps.isNotEmpty){
//       return Expense.fromMap(maps.first);
//     }

//     return null;
//   }
  

//   // update expense
//   Future <void> updateExpense(Expense expense) async {
//     final db = await database;
//     await db.update(
//       'expenses', 
//       expense.toMap(),
//       where: 'id=?',
//       whereArgs: [expense.id]
//       );
//   }

//   // delete expense by ide
//   Future <void> deleteExpense(int id) async {
//     final db = await database;
//     await db.delete(
//       'expenses',
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }

//   // ✅ CLOSE DB (optional but good practice)
//   Future<void> close() async {
//     final db = await database;
//     await db.close();
//     _database = null;
//   }


// }




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
        paymentMethod TEXT NOT NULL
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