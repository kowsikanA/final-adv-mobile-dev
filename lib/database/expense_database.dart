import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';

/// Enum representing how often a recurring expense should repeat.
/// - [weekly]: Repeats every 7 days
/// - [monthly]: Repeats every month on the same day
enum RecurringFrequency { weekly, monthly }

/// Model for recurring/repeating expenses.
/// Stores a template that will auto-generate individual Expense instances
/// on the specified schedule (weekly or monthly) up to the current date.
class RecurringExpense {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String paymentMethod;
  final String? description;
  final String? location;
  final DateTime startDate;
  final RecurringFrequency frequency;
  final DateTime nextDueDate;
  final bool isActive;

  const RecurringExpense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    this.description,
    this.location,
    required this.startDate,
    required this.frequency,
    required this.nextDueDate,
    this.isActive = true,
  });

  /// Creates a copy of this RecurringExpense with the specified fields replaced.
  /// Used for non-breaking updates to recurring expense templates.
  RecurringExpense copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    String? paymentMethod,
    String? description,
    String? location,
    DateTime? startDate,
    RecurringFrequency? frequency,
    DateTime? nextDueDate,
    bool? isActive,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Converts a database row (Map) into a RecurringExpense object.
  /// Parses date strings and frequency enum values from database format.
  factory RecurringExpense.fromMap(Map<String, dynamic> map) {
    return RecurringExpense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      paymentMethod: map['paymentMethod'] as String,
      description: map['description'] as String?,
      location: map['location'] as String?,
      startDate: DateTime.parse(map['startDate'] as String),
      frequency: (map['frequency'] as String) == 'monthly'
          ? RecurringFrequency.monthly
          : RecurringFrequency.weekly,
      nextDueDate: DateTime.parse(map['nextDueDate'] as String),
      isActive: (map['isActive'] as int? ?? 1) == 1,
    );
  }

  /// Converts this RecurringExpense into a Map suitable for database insertion.
  /// Includes the user UID and converts enums/dates to database-compatible formats.
  Map<String, dynamic> toMap(String uid) {
    return {
      'id': id,
      'uid': uid,
      'title': title,
      'amount': amount,
      'category': category,
      'paymentMethod': paymentMethod,
      'description': description,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'frequency': frequency == RecurringFrequency.monthly ? 'monthly' : 'weekly',
      'nextDueDate': nextDueDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }
}

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

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, _) async {
        await _ensureAuxTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _ensureAuxTables(db);
        }
        if (FirebaseAuth.instance.currentUser != null) {
          await _ensureTable(db);
        }
      },
    );
  }

  Future<void> _ensureAuxTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monthly_budgets (
        uid TEXT NOT NULL,
        monthKey TEXT NOT NULL,
        amount REAL NOT NULL,
        PRIMARY KEY(uid, monthKey)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS category_budgets (
        uid TEXT NOT NULL,
        monthKey TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        PRIMARY KEY(uid, monthKey, category)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        description TEXT,
        location TEXT,
        startDate TEXT NOT NULL,
        frequency TEXT NOT NULL,
        nextDueDate TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  // ✅ Create table ONLY if it does not exist
  Future<void> _ensureTable(Database db) async {
    await _ensureAuxTables(db);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        dueDate TEXT,
        description TEXT,
        paymentMethod TEXT NOT NULL,
        location TEXT,
        isPaid INTEGER NOT NULL DEFAULT 0
      )
    ''');

    final columns = await db.rawQuery('PRAGMA table_info($_tableName)');
    final columnNames = columns.map((e) => e['name'] as String).toSet();

    if (!columnNames.contains('dueDate')) {
      await db.execute('ALTER TABLE $_tableName ADD COLUMN dueDate TEXT');
    }

    if (!columnNames.contains('isPaid')) {
      await db.execute(
        'ALTER TABLE $_tableName ADD COLUMN isPaid INTEGER NOT NULL DEFAULT 0',
      );
    }
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

  Future<void> insertExpenses(List<Expense> expenses) async {
    if (expenses.isEmpty) return;
    final db = await database;
    await _ensureTable(db);
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final expense in expenses) {
        batch.insert(_tableName, expense.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw ArgumentError('Expense ID is required for updates');
    }

    final db = await database;
    await _ensureTable(db);
    await db.update(
      _tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
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

  /// Stores or updates the monthly budget for the current user.
  /// Handles both overall budget amount and per-category budget limits.
  /// [monthKey] format: 'yyyy-MM' (e.g., '2026-03')
  /// [categoryBudgets]: Map of category names to their individual budget limits.
  /// Uses a database transaction to atomically update both overall and category budgets.
  Future<void> upsertMonthlyBudget({
    required String monthKey,
    required double amount,
    required Map<String, double> categoryBudgets,
  }) async {
    final db = await database;
    await _ensureTable(db);

    await db.transaction((txn) async {
      await txn.insert(
        'monthly_budgets',
        {
          'uid': _uid,
          'monthKey': monthKey,
          'amount': amount,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'category_budgets',
        where: 'uid = ? AND monthKey = ?',
        whereArgs: [_uid, monthKey],
      );

      for (final entry in categoryBudgets.entries) {
        await txn.insert(
          'category_budgets',
          {
            'uid': _uid,
            'monthKey': monthKey,
            'category': entry.key,
            'amount': entry.value,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Retrieves the overall monthly budget amount for the specified month.
  /// Returns null if no budget has been set for that month.
  /// [monthKey] format: 'yyyy-MM' (e.g., '2026-03')
  Future<double?> getMonthlyBudget(String monthKey) async {
    final db = await database;
    await _ensureTable(db);
    final rows = await db.query(
      'monthly_budgets',
      where: 'uid = ? AND monthKey = ?',
      whereArgs: [_uid, monthKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['amount'] as num).toDouble();
  }

  /// Retrieves all category-specific budget limits for the specified month.
  /// Returns a Map of category names to budget amounts.
  /// [monthKey] format: 'yyyy-MM' (e.g., '2026-03')
  /// 
  /// Used to compare actual spending against per-category targets
  /// in the categories tab and filter views.
  Future<Map<String, double>> getCategoryBudgets(String monthKey) async {
    final db = await database;
    await _ensureTable(db);
    final rows = await db.query(
      'category_budgets',
      where: 'uid = ? AND monthKey = ?',
      whereArgs: [_uid, monthKey],
    );

    final result = <String, double>{};
    for (final row in rows) {
      result[row['category'] as String] = (row['amount'] as num).toDouble();
    }
    return result;
  }

  /// Inserts a new recurring expense template into the database.
  /// Returns the row ID of the newly inserted recurring expense.
  /// 
  /// The template will be used by [generateDueRecurringExpenses] to create
  /// individual expense entries on the specified schedule.
  Future<int> insertRecurringExpense(RecurringExpense recurringExpense) async {
    final db = await database;
    await _ensureTable(db);
    return db.insert('recurring_expenses', recurringExpense.toMap(_uid));
  }

  /// Fetches all recurring expense templates for the current user.
  /// Results are ordered by next due date (soonest first).
  /// This is used to populate the recurring expenses UI in the categories tab.
  Future<List<RecurringExpense>> getRecurringExpenses() async {
    final db = await database;
    await _ensureTable(db);
    final rows = await db.query(
      'recurring_expenses',
      where: 'uid = ?',
      whereArgs: [_uid],
      orderBy: 'nextDueDate ASC',
    );
    return rows.map(RecurringExpense.fromMap).toList();
  }

  /// Deletes a recurring expense template by ID.
  /// Removes the template (no new instances will be generated),
  /// but does NOT delete already-generated individual expense entries.
  Future<void> deleteRecurringExpense(int id) async {
    final db = await database;
    await _ensureTable(db);
    await db.delete(
      'recurring_expenses',
      where: 'id = ? AND uid = ?',
      whereArgs: [id, _uid],
    );
  }

  /// Auto-generates individual Expense entries from all active recurring templates.
  /// Creates an expense instance for each recurrence up to the specified date (default: now).
  /// Updates each template's [nextDueDate] to the next scheduled date.
  /// Uses a database transaction to ensure atomic updates.
  /// 
  /// Returns the count of newly created expense entries.
  /// Called on app startup to ensure no recurring expenses are missed.
  Future<int> generateDueRecurringExpenses({DateTime? now}) async {
    final db = await database;
    await _ensureTable(db);
    final current = now ?? DateTime.now();
    int createdCount = 0;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'recurring_expenses',
        where: 'uid = ? AND isActive = 1',
        whereArgs: [_uid],
      );

      for (final row in rows) {
        final recurring = RecurringExpense.fromMap(row);
        var dueDate = recurring.nextDueDate;
        var localCreated = 0;

        while (!dueDate.isAfter(current)) {
          await txn.insert(
            _tableName,
            Expense(
              title: recurring.title,
              amount: recurring.amount,
              category: recurring.category,
              date: dueDate,
              dueDate: dueDate,
              description: recurring.description,
              paymentMethod: recurring.paymentMethod,
              location: recurring.location,
              isPaid: false,
            ).toMap(),
          );
          localCreated++;

          dueDate = recurring.frequency == RecurringFrequency.weekly
              ? dueDate.add(const Duration(days: 7))
              : DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
        }

        if (localCreated > 0) {
          createdCount += localCreated;
          await txn.update(
            'recurring_expenses',
            {'nextDueDate': dueDate.toIso8601String()},
            where: 'id = ?',
            whereArgs: [recurring.id],
          );
        }
      }
    });

    return createdCount;
  }
}