// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'database/expense_database.dart';
// import 'models/expense.dart';

// class AddExpensePage extends StatefulWidget {
//   const AddExpensePage({super.key});

//   @override
//   State<AddExpensePage> createState() => _AddExpensePageState();
// }

// class _AddExpensePageState extends State<AddExpensePage> {
//   final _formKey = GlobalKey<FormState>();

//   final _titleCtrl = TextEditingController();
//   final _amountCtrl = TextEditingController();
//   final _descCtrl = TextEditingController();

//   DateTime? _date = DateTime.now();

//   // simple starter lists
//   final List<String> _categories = const [
//     "Food",
//     "Transport",
//     "Bills",
//     "Shopping",
//     "Entertainment",
//     "Health",
//     "Other"
//   ];

//   final List<String> _paymentMethods = const [
//     "Cash",
//     "Debit",
//     "Credit",
//     "Online",
//   ];

//   String _selectedCategory = "Food";
//   String _selectedPayment = "Debit";

//   @override
//   void dispose() {
//     _titleCtrl.dispose();
//     _amountCtrl.dispose();
//     _descCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _pickDate() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _date ?? now,
//       firstDate: DateTime(now.year - 5),
//       lastDate: DateTime(now.year + 5),
//     );

//     if (picked != null) {
//       setState(() => _date = picked);
//     }
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;

//     final amount = double.tryParse(_amountCtrl.text.trim());
//     if (amount == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Amount must be a number")),
//       );
//       return;
//     }

//     final expense = Expense(
//       title: _titleCtrl.text.trim(),
//       amount: amount,
//       category: _selectedCategory,
//       date: _date,
//       description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
//       paymentMethod: _selectedPayment,
//     );

//     await ExpenseDatabase.instance.insertExpense(expense);

//     HapticFeedback.mediumImpact();
//     if (!mounted) return;
//     Navigator.pop(context, true); // tell dashboard to refresh
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Add Expense")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(
//                 controller: _titleCtrl,
//                 decoration: const InputDecoration(
//                   labelText: "Title",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) return "Title is required";
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),

//               TextFormField(
//                 controller: _amountCtrl,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   labelText: "Amount",
//                   hintText: "e.g., 12.50",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) return "Amount is required";
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),

//               DropdownButtonFormField<String>(
//                 value: _selectedCategory,
//                 items: _categories
//                     .map((c) => DropdownMenuItem(value: c, child: Text(c)))
//                     .toList(),
//                 onChanged: (v) => setState(() => _selectedCategory = v!),
//                 decoration: const InputDecoration(
//                   labelText: "Category",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               DropdownButtonFormField<String>(
//                 value: _selectedPayment,
//                 items: _paymentMethods
//                     .map((p) => DropdownMenuItem(value: p, child: Text(p)))
//                     .toList(),
//                 onChanged: (v) => setState(() => _selectedPayment = v!),
//                 decoration: const InputDecoration(
//                   labelText: "Payment Method",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               OutlinedButton.icon(
//                 onPressed: _pickDate,
//                 icon: const Icon(Icons.calendar_month_outlined),
//                 label: Text(
//                   _date == null
//                       ? "Pick date"
//                       : "Date: ${_date!.toLocal().toString().split(' ').first}",
//                 ),
//               ),
//               const SizedBox(height: 12),

//               TextFormField(
//                 controller: _descCtrl,
//                 maxLines: 3,
//                 decoration: const InputDecoration(
//                   labelText: "Description (optional)",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               ElevatedButton(
//                 onPressed: _save,
//                 child: const Text("Save Expense"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database/expense_database.dart';
import 'models/expense.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? _date = DateTime.now();

  final List<String> _categories = const [
    "Food",
    "Transport",
    "Bills",
    "Shopping",
    "Entertainment",
    "Health",
    "Other"
  ];

  final List<String> _paymentMethods = const [
    "Cash",
    "Debit",
    "Credit",
    "Online",
  ];

  String _selectedCategory = "Food";
  String _selectedPayment = "Debit";
  bool _showDescription = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      HapticFeedback.lightImpact();
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amount must be a number")),
      );
      return;
    }

    final expense = Expense(
      title: _titleCtrl.text.trim(),
      amount: amount,
      category: _selectedCategory,
      date: _date,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      paymentMethod: _selectedPayment,
    );

    await ExpenseDatabase.instance.insertExpense(expense);

    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Expense"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Title",
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Title is required";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Amount",
                          hintText: "e.g., 12.50",
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Amount is required";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category chips (Interaction + Haptic)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Category",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((c) {
                          final selected = _selectedCategory == c;
                          return ChoiceChip(
                            label: Text(c),
                            selected: selected,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = c);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Payment chips (Interaction + Haptic)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Payment",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _paymentMethods.map((p) {
                          final selected = _selectedPayment == p;
                          return ChoiceChip(
                            label: Text(p),
                            selected: selected,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedPayment = p);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Date button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(
                            _date == null
                                ? "Pick date"
                                : "Date: ${_date!.toLocal().toString().split(' ').first}",
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Animated description toggle (Animation)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Add description",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          Switch(
                            value: _showDescription,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _showDescription = v);
                            },
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: _showDescription
                            ? Column(
                                children: [
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _descCtrl,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: "Description (optional)",
                                      prefixIcon: Icon(Icons.notes_outlined),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label: const Text("Save Expense"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}