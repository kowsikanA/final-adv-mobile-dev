// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import 'database/expense_database.dart';
// import 'models/expense.dart';
// import 'add_expense.dart';

// class ExpensePage extends StatefulWidget {
//   const ExpensePage({super.key});

//   @override
//   State<ExpensePage> createState() => _ExpensePageState();
// }

// class _ExpensePageState extends State<ExpensePage> {
//   final ExpenseDatabase _db = ExpenseDatabase.instance;
//   List<Expense> _expenses = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadExpenses();
//   }

//   Future<void> _loadExpenses() async {
//     final data = await _db.getExpenses();
//     setState(() => _expenses = data);
//   }

//   Future<void> _addExpense() async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const AddExpensePage(),
//       ),
//     );
//     _loadExpenses();
//   }

//   Future<void> _deleteExpense(int id) async {
//     await _db.deleteExpense(id);
//     _loadExpenses();
//   }

//   Future<void> _logout() async {
//     await FirebaseAuth.instance.signOut();
//     // AuthGate will automatically redirect to LoginPage
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Expenses",
//           style: TextStyle(fontWeight: FontWeight.w700),
//         ),
//         actions: [
//           IconButton(
//             tooltip: "Logout",
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _addExpense,
//         backgroundColor: Colors.black,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//       body: _expenses.isEmpty
//           ? const Center(
//               child: Text(
//                 "No expenses yet",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             )
//           : ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: _expenses.length,
//               itemBuilder: (context, index) {
//                 final expense = _expenses[index];

//                 return Card(
//                   elevation: 2,
//                   margin: const EdgeInsets.symmetric(vertical: 6),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: ListTile(
//                     title: Text(
//                       expense.title,
//                       style: const TextStyle(fontWeight: FontWeight.w700),
//                     ),
//                     subtitle: Text(
//                       "\$${expense.amount.toStringAsFixed(2)} • ${expense.category}",
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.redAccent),
//                       onPressed: () => _deleteExpense(expense.id!),
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'database/expense_database.dart';
import 'models/expense.dart';
import 'add_expense.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final ExpenseDatabase _db = ExpenseDatabase.instance;
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final data = await _db.getExpenses();
    if (!mounted) return;
    setState(() => _expenses = data);
  }

  double get _total {
    double sum = 0;
    for (final e in _expenses) {
      sum += e.amount;
    }
    return sum;
  }

  String _money(double v) => "\$${v.toStringAsFixed(2)}";

  Color _chipColor(String category, ColorScheme scheme) {
    switch (category.toLowerCase()) {
      case "food":
        return scheme.primaryContainer;
      case "transport":
        return scheme.secondaryContainer;
      case "bills":
        return scheme.tertiaryContainer;
      case "shopping":
        return scheme.primaryContainer.withOpacity(0.75);
      case "entertainment":
        return scheme.secondaryContainer.withOpacity(0.75);
      case "health":
        return scheme.tertiaryContainer.withOpacity(0.75);
      default:
        return scheme.surfaceContainerHighest;
    }
  }

  Future<void> _addExpense() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => const AddExpensePage(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    _loadExpenses();
  }

  Future<void> _deleteExpense(int id) async {
    HapticFeedback.mediumImpact();
    await _db.deleteExpense(id);
    _loadExpenses();
  }

  Future<void> _logout() async {
    HapticFeedback.selectionClick();
    await FirebaseAuth.instance.signOut();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete expense?"),
        content: const Text("This can’t be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Expenses"),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add),
        label: const Text("Add"),
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
          children: [
            // Summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.insights_rounded, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total spending",
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _money(_total),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "${_expenses.length} items",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _expenses.isEmpty
                  ? Padding(
                      key: const ValueKey("empty"),
                      padding: const EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long, size: 56, color: scheme.onSurfaceVariant),
                          const SizedBox(height: 10),
                          Text(
                            "No expenses yet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Tap “Add” to create your first expense.",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      key: const ValueKey("list"),
                      children: [
                        for (final expense in _expenses) ...[
                          Dismissible(
                            key: ValueKey(expense.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDelete(context),
                            onDismissed: (_) => _deleteExpense(expense.id!),
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: scheme.errorContainer,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(Icons.delete, color: scheme.onErrorContainer),
                            ),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                title: Text(
                                  expense.title,
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _chipColor(expense.category, scheme),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          expense.category,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: scheme.surfaceContainerHighest.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          expense.paymentMethod,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _money(expense.amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    IconButton(
                                      tooltip: "Delete",
                                      icon: Icon(Icons.delete_outline, color: scheme.error),
                                      onPressed: () async {
                                        final ok = await _confirmDelete(context);
                                        if (ok) _deleteExpense(expense.id!);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}