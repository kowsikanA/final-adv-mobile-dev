import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'database/expense_database.dart';
import 'models/expense.dart';
import 'add_expense.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  late Future<List<Expense>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _expensesFuture = ExpenseDatabase.instance.getExpenses();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return "No date";
    return d.toLocal().toString().split(' ').first; // YYYY-MM-DD
  }

  double _total(List<Expense> items) {
    double sum = 0;
    for (final e in items) {
      sum += e.amount;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;
          final total = _total(expenses);

          return RefreshIndicator(
            onRefresh: () async {
              setState(_refresh);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Spent",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "\$${total.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text("${expenses.length} items"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Expenses list
                if (expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text("No expenses yet. Tap + to add one.")),
                  )
                else
                  ...expenses.map((e) {
                    return Card(
                      elevation: 0,
                      child: ListTile(
                        title: Text(
                          e.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Chip(label: Text(e.category)),
                                Chip(label: Text(e.paymentMethod)),
                                Chip(label: Text(_formatDate(e.date))),
                              ],
                            ),
                            if ((e.description ?? "").trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  e.description!,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "\$${e.amount.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (e.id == null) return;
                                await ExpenseDatabase.instance.deleteExpense(e.id!);

                                HapticFeedback.lightImpact();
                                setState(_refresh);
                              },
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {

          HapticFeedback.lightImpact();
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddExpensePage()),
          );

          if (added == true) {
            setState(_refresh);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}