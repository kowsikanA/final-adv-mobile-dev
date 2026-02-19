import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

class ExpenseDatabase {
  static final ExpenseDatabase instance = ExpenseDatabase._init();
  ExpenseDatabase._init();

  static Database? _database;

  Future <Database> get database async{
    if (_database != null ) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // initialize database
  Future <Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenseDatabase.db');

    return await openDatabase(
      path, 
      version: 1,
      onCreate: (db, version) async{
        await db.execute('''
                          CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, 
                          title TEXT NOT NULL ,  
                          amount REAL NOT NULL, 
                          category TEXT NOT NULL,
                          date TEXT,
                          description TEXT, 
                          paymentMethod TEXT NOT NULL
                          )
                          ''');
    
      },
    );
  }

  // adding expense
  Future <int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert(
      'expenses', 
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // getting all expenses
  Future <List<Expense>> getExpenses() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC' // order by last added
    );

    List <Expense> expenses = [];

    if (maps.length > 0){
      for(int i = 0; i < maps.length; i++){
        expenses.add(Expense.fromMap(maps[i]));
      }
    }

    return expenses;
  }

  // getting all expenses
  Future <Expense?> getExpensesByID(int id) async {
    final db = await database;

    final  maps = await db.query(
      'expenses',
      where: 'id=?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty){
      return Expense.fromMap(maps.first);
    }

    return null;
  }
  

  // update expense
  Future <void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses', 
      expense.toMap(),
      where: 'id=?',
      whereArgs: [expense.id]
      );
  }

  // delete expense by ide
  Future <void> deleteExpense(int id) async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ CLOSE DB (optional but good practice)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }


}


