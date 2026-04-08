// import 'dart:io';

// import 'package:csv/csv.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/widgets.dart' as pw;

// import 'database/expense_database.dart';
// import 'models/expense.dart';
// import 'add_expense.dart';
// import 'expense_detail_page.dart';
// import 'contact_page.dart';
// import 'charts_page.dart';
// import 'ai_chat_page.dart';

// class ExpensePage extends StatefulWidget {
//   const ExpensePage({super.key});

//   @override
//   State<ExpensePage> createState() => _ExpensePageState();
// }

// class _ExpensePageState extends State<ExpensePage> {
//   final ExpenseDatabase _db = ExpenseDatabase.instance;
//   final TextEditingController _searchController = TextEditingController();

//   static const List<String> _defaultCategories = [
//     'Food',
//     'Transport',
//     'Bills',
//     'Shopping',
//     'Entertainment',
//     'Health',
//     'Other',
//   ];

//   static const List<String> _paymentMethods = [
//     'Cash',
//     'Debit',
//     'Credit',
//     'Online',
//   ];

//   List<Expense> _expenses = [];
//   List<RecurringExpense> _recurringExpenses = [];

//   // ===== SEARCH & FILTER STATE =====
//   // Controls for filtering expenses in the home tab
//   String _searchText = '';  // Live text search (case-insensitive)
//   String? _selectedCategoryFilter;  // null = show all categories
//   String? _selectedPaymentFilter;   // null = show all payment methods
//   DateTimeRange? _selectedDateRange;  // null = show all dates
//   double? _minAmountFilter;  // null = no minimum
//   double? _maxAmountFilter;  // null = no maximum

//   // ===== BUDGET & RECURRING STATE =====
//   // Monthly budget tracking for the current month
//   double? _monthlyBudget;  // Overall budget target
//   Map<String, double> _categoryBudgets = {};  // Per-category budget limits

//   int _listAnimationSeed = 0;
//   int _selectedIndex = 0;

//   late final AiChatPage _aiChatPage;
//   late final ContactPage _contactPage;

//   @override
//   void initState() {
//     super.initState();
//     _aiChatPage = const AiChatPage();
//     _contactPage = const ContactPage();
//     _searchController.addListener(() {
//       setState(() {
//         _searchText = _searchController.text.trim().toLowerCase();
//       });
//     });
//     _loadExpenses();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   /// Returns the current month key in 'yyyy-MM' format (e.g., '2026-03').
//   /// Used as a key for monthly budget storage and filtering.
//   String get _monthKey {
//     final now = DateTime.now();
//     final month = now.month.toString().padLeft(2, '0');
//     return '${now.year}-$month';
//   }

//   /// Returns the filtered list of expenses based on all active filter criteria.
//   /// Applies filters in order: text search, category, payment method, date range, amount range.
//   /// All filters are additive (AND logic) — an expense must satisfy ALL active filters to appear.
//   List<Expense> get _filteredExpenses {
//     return _expenses.where((expense) {
//       if (_searchText.isNotEmpty) {
//         final text = [
//           expense.title,
//           expense.description ?? '',
//           expense.location ?? '',
//           expense.category,
//           expense.paymentMethod,
//         ].join(' ').toLowerCase();

//         if (!text.contains(_searchText)) {
//           return false;
//         }
//       }

//       if (_selectedCategoryFilter != null &&
//           expense.category != _selectedCategoryFilter) {
//         return false;
//       }

//       if (_selectedPaymentFilter != null &&
//           expense.paymentMethod != _selectedPaymentFilter) {
//         return false;
//       }

//       if (_selectedDateRange != null && expense.date != null) {
//         final d = DateTime(expense.date!.year, expense.date!.month, expense.date!.day);
//         final start = DateTime(
//           _selectedDateRange!.start.year,
//           _selectedDateRange!.start.month,
//           _selectedDateRange!.start.day,
//         );
//         final end = DateTime(
//           _selectedDateRange!.end.year,
//           _selectedDateRange!.end.month,
//           _selectedDateRange!.end.day,
//         );
//         if (d.isBefore(start) || d.isAfter(end)) {
//           return false;
//         }
//       }

//       if (_minAmountFilter != null && expense.amount < _minAmountFilter!) {
//         return false;
//       }

//       if (_maxAmountFilter != null && expense.amount > _maxAmountFilter!) {
//         return false;
//       }

//       return true;
//     }).toList();
//   }

//   /// Loads all expenses, recurring templates, and budgets from the database.
//   /// Also auto-generates any due recurring expenses via [generateDueRecurringExpenses].
//   /// If new expenses were generated, shows a snackbar notification.
//   /// Refreshes the list animation seed to restart any staggered animations.
//   /// Called on app startup and when returning from edit/detail pages.
//   Future<void> _loadExpenses() async {
//     final generated = await _db.generateDueRecurringExpenses();
//     final data = await _db.getExpenses();
//     final recurring = await _db.getRecurringExpenses();
//     final monthlyBudget = await _db.getMonthlyBudget(_monthKey);
//     final categoryBudgets = await _db.getCategoryBudgets(_monthKey);
//     if (!mounted) return;

//     if (generated > 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Added $generated recurring expense(s) automatically.')),
//       );
//     }

//     setState(() {
//       _expenses = data;
//       _recurringExpenses = recurring;
//       _monthlyBudget = monthlyBudget;
//       _categoryBudgets = categoryBudgets;
//       _listAnimationSeed++;
//     });
//   }

//   double get _total {
//     double sum = 0;
//     for (final e in _expenses) {
//       sum += e.amount;
//     }
//     return sum;
//   }

//   /// Returns the total amount spent in the current month.
//   /// Used for budget progress bar in the home and categories tabs.
//   double get _monthlyTotal {
//     final now = DateTime.now();
//     return _expenses
//         .where((e) =>
//             e.date != null && e.date!.year == now.year && e.date!.month == now.month)
//         .fold<double>(0, (sum, e) => sum + e.amount);
//   }

//   /// Returns a map of category name to total spending for the current month.
//   /// Used in the categories tab to show per-category totals with over-budget alerts.
//   Map<String, double> get _monthlyByCategory {
//     final now = DateTime.now();
//     final totals = <String, double>{};
//     for (final expense in _expenses) {
//       if (expense.date == null ||
//           expense.date!.year != now.year ||
//           expense.date!.month != now.month) {
//         continue;
//       }
//       totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
//     }
//     return totals;
//   }

//   String _money(double v) => "\$${v.toStringAsFixed(2)}";

//   Color _chipColor(String category, ColorScheme scheme) {
//     switch (category.toLowerCase()) {
//       case "food":
//         return scheme.primaryContainer;
//       case "transport":
//         return scheme.secondaryContainer;
//       case "bills":
//         return scheme.tertiaryContainer;
//       case "shopping":
//           return scheme.primaryContainer.withValues(alpha: 0.75);
//       case "entertainment":
//           return scheme.secondaryContainer.withValues(alpha: 0.75);
//       case "health":
//           return scheme.tertiaryContainer.withValues(alpha: 0.75);
//       default:
//         return scheme.surfaceContainerHighest;
//     }
//   }


//   String _formatDueDate(DateTime? date) {
//     if (date == null) return 'No due date';
//     return DateFormat('yyyy-MM-dd').format(date);
//   }

//   bool _isOverdue(Expense expense) {
//     if (expense.dueDate == null || expense.isPaid) return false;
//     final due = DateTime(
//       expense.dueDate!.year,
//       expense.dueDate!.month,
//       expense.dueDate!.day,
//     );
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     return due.isBefore(today);
//   }

//   Widget _buildStatusChip(Expense expense, ColorScheme scheme) {
//     final label = expense.isPaid
//         ? 'Paid'
//         : _isOverdue(expense)
//             ? 'Overdue'
//             : 'Unpaid';
//     final color = expense.isPaid
//         ? Colors.green
//         : _isOverdue(expense)
//             ? scheme.error
//             : scheme.primary;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.12),
//         borderRadius: BorderRadius.circular(999),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           fontWeight: FontWeight.w800,
//           color: color,
//         ),
//       ),
//     );
//   }

//   Future<void> _addExpense() async {
//     HapticFeedback.selectionClick();
//     await Navigator.of(context).push(
//       PageRouteBuilder(
//         transitionDuration: const Duration(milliseconds: 250),
//             pageBuilder: (_, _, _) => const AddExpensePage(),
//             transitionsBuilder: (_, animation, _, child) {
//           final curved = CurvedAnimation(
//             parent: animation,
//             curve: Curves.easeOutCubic,
//           );
//           return FadeTransition(
//             opacity: curved,
//             child: SlideTransition(
//               position: Tween<Offset>(
//                 begin: const Offset(0, 0.04),
//                 end: Offset.zero,
//               ).animate(curved),
//               child: child,
//             ),
//           );
//         },
//       ),
//     );
//     await _loadExpenses();
//   }

//   Future<void> _deleteExpense(Expense expense) async {
//     final removedIndex = _expenses.indexWhere((e) => e.id == expense.id);
//     if (removedIndex == -1) return;

//     HapticFeedback.mediumImpact();

//     setState(() {
//       _expenses.removeWhere((e) => e.id == expense.id);
//     });

//     var isUndo = false;
//     final messenger = ScaffoldMessenger.of(context);
//     messenger.hideCurrentSnackBar();

//     final controller = messenger.showSnackBar(
//       SnackBar(
//         content: Text('Deleted "${expense.title}"'),
//         duration: const Duration(seconds: 3),
//         action: SnackBarAction(
//           label: 'Undo',
//           onPressed: () {
//             isUndo = true;
//             if (!mounted) return;
//             setState(() {
//               _expenses.insert(removedIndex, expense);
//             });
//           },
//         ),
//       ),
//     );

//     await _db.deleteExpense(expense.id!);
//     await controller.closed;

//     if (isUndo) {
//       await _db.insertExpense(
//         Expense(
//           title: expense.title,
//           amount: expense.amount,
//           category: expense.category,
//           date: expense.date,
//           dueDate: expense.dueDate,
//           description: expense.description,
//           paymentMethod: expense.paymentMethod,
//           location: expense.location,
//           isPaid: expense.isPaid,
//         ),
//       );
//       await _loadExpenses();
//     }
//   }

//   Future<void> _logout() async {
//     HapticFeedback.selectionClick();
//     await FirebaseAuth.instance.signOut();
//   }

//   /// Opens a bottom sheet with search filters.
//   /// Allows filtering by: category, payment method, date range, min/max amount.
//   /// Changes are only applied when the 'Apply' button is pressed.
//   /// 'Clear' button removes all active filters.
//   Future<void> _openFilters() async {
//     final minCtrl = TextEditingController(
//       text: _minAmountFilter?.toStringAsFixed(2) ?? '',
//     );
//     final maxCtrl = TextEditingController(
//       text: _maxAmountFilter?.toStringAsFixed(2) ?? '',
//     );
//     String? category = _selectedCategoryFilter;
//     String? payment = _selectedPaymentFilter;
//     DateTimeRange? dateRange = _selectedDateRange;

//     await showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return Padding(
//               padding: EdgeInsets.only(
//                 left: 16,
//                 right: 16,
//                 top: 16,
//                 bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
//               ),
//               child: Wrap(
//                 runSpacing: 12,
//                 children: [
//                   const Text(
//                     'Filters',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
//                   ),
//                   DropdownButtonFormField<String?>(
//                     initialValue: category,
//                     decoration: const InputDecoration(labelText: 'Category'),
//                     items: [
//                       const DropdownMenuItem<String?>(value: null, child: Text('All')),
//                       ..._defaultCategories.map(
//                         (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
//                       ),
//                     ],
//                     onChanged: (value) => setModalState(() => category = value),
//                   ),
//                   DropdownButtonFormField<String?>(
//                     initialValue: payment,
//                     decoration: const InputDecoration(labelText: 'Payment Method'),
//                     items: [
//                       const DropdownMenuItem<String?>(value: null, child: Text('All')),
//                       ..._paymentMethods.map(
//                         (p) => DropdownMenuItem<String?>(value: p, child: Text(p)),
//                       ),
//                     ],
//                     onChanged: (value) => setModalState(() => payment = value),
//                   ),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: () async {
//                             final now = DateTime.now();
//                             final picked = await showDateRangePicker(
//                               context: context,
//                               firstDate: DateTime(now.year - 10),
//                               lastDate: DateTime(now.year + 10),
//                               initialDateRange: dateRange,
//                             );
//                             if (picked != null) {
//                               setModalState(() => dateRange = picked);
//                             }
//                           },
//                           icon: const Icon(Icons.date_range_outlined),
//                           label: Text(
//                             dateRange == null
//                                 ? 'Any date'
//                                 : '${DateFormat('MMM d').format(dateRange!.start)} - ${DateFormat('MMM d').format(dateRange!.end)}',
//                           ),
//                         ),
//                       ),
//                       if (dateRange != null)
//                         IconButton(
//                           onPressed: () => setModalState(() => dateRange = null),
//                           icon: const Icon(Icons.close),
//                         ),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: minCtrl,
//                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                           decoration: const InputDecoration(labelText: 'Min amount'),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: TextField(
//                           controller: maxCtrl,
//                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                           decoration: const InputDecoration(labelText: 'Max amount'),
//                         ),
//                       ),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextButton(
//                           onPressed: () {
//                             setState(() {
//                               _selectedCategoryFilter = null;
//                               _selectedPaymentFilter = null;
//                               _selectedDateRange = null;
//                               _minAmountFilter = null;
//                               _maxAmountFilter = null;
//                             });
//                             Navigator.pop(context);
//                           },
//                           child: const Text('Clear'),
//                         ),
//                       ),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               _selectedCategoryFilter = category;
//                               _selectedPaymentFilter = payment;
//                               _selectedDateRange = dateRange;
//                               _minAmountFilter =
//                                   double.tryParse(minCtrl.text.trim());
//                               _maxAmountFilter =
//                                   double.tryParse(maxCtrl.text.trim());
//                             });
//                             Navigator.pop(context);
//                           },
//                           child: const Text('Apply'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   /// Opens a dialog to set monthly budget goals.
//   /// Supports both an overall monthly total budget and per-category budgets.
//   /// Saved values are stored via [upsertMonthlyBudget] and displayed as
//   /// a progress bar in the home and categories tabs.
//   Future<void> _openBudgetDialog() async {
//     final totalCtrl = TextEditingController(
//       text: _monthlyBudget?.toStringAsFixed(2) ?? '',
//     );
//     final categoryControllers = {
//       for (final category in _defaultCategories)
//         category: TextEditingController(
//           text: _categoryBudgets[category]?.toStringAsFixed(2) ?? '',
//         ),
//     };

//     final saved = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Monthly Budget Goals'),
//           content: SizedBox(
//             width: 420,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: totalCtrl,
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                     decoration: const InputDecoration(
//                       labelText: 'Overall monthly budget',
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   ..._defaultCategories.map(
//                     (category) => Padding(
//                       padding: const EdgeInsets.only(bottom: 10),
//                       child: TextField(
//                         controller: categoryControllers[category],
//                         keyboardType:
//                             const TextInputType.numberWithOptions(decimal: true),
//                         decoration: InputDecoration(
//                           labelText: '$category budget (optional)',
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                   final nav = Navigator.of(context);
//                 final total = double.tryParse(totalCtrl.text.trim()) ?? 0;
//                 final perCategory = <String, double>{};
//                 for (final entry in categoryControllers.entries) {
//                   final value = double.tryParse(entry.value.text.trim());
//                   if (value != null && value > 0) {
//                     perCategory[entry.key] = value;
//                   }
//                 }
//                 await _db.upsertMonthlyBudget(
//                   monthKey: _monthKey,
//                   amount: total,
//                   categoryBudgets: perCategory,
//                 );
//                   nav.pop(true);
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );

//     if (saved == true) {
//       await _loadExpenses();
//     }
//   }

//   /// Opens a dialog to create a new recurring expense template.
//   /// Collects: title, amount, category, payment method, frequency (weekly/monthly), start date.
//   /// Saves to database via [insertRecurringExpense].
//   /// The next time [_loadExpenses] runs, [generateDueRecurringExpenses] will
//   /// auto-create individual expense entries up to the current date.
//   Future<void> _openRecurringDialog() async {
//     final titleCtrl = TextEditingController();
//     final amountCtrl = TextEditingController();
//     final descCtrl = TextEditingController();
//     final locationCtrl = TextEditingController();
//     String category = _defaultCategories.first;
//     String payment = _paymentMethods[1];
//     RecurringFrequency frequency = RecurringFrequency.monthly;
//     DateTime startDate = DateTime.now();

//     final created = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return AlertDialog(
//               title: const Text('Add Recurring Expense'),
//               content: SizedBox(
//                 width: 420,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       TextField(
//                         controller: titleCtrl,
//                         decoration: const InputDecoration(labelText: 'Title'),
//                       ),
//                       const SizedBox(height: 10),
//                       TextField(
//                         controller: amountCtrl,
//                         keyboardType:
//                             const TextInputType.numberWithOptions(decimal: true),
//                         decoration: const InputDecoration(labelText: 'Amount'),
//                       ),
//                       const SizedBox(height: 10),
//                       DropdownButtonFormField<String>(
//                         initialValue: category,
//                         items: _defaultCategories
//                             .map((c) => DropdownMenuItem(value: c, child: Text(c)))
//                             .toList(),
//                         onChanged: (v) {
//                           if (v != null) {
//                             setModalState(() => category = v);
//                           }
//                         },
//                         decoration: const InputDecoration(labelText: 'Category'),
//                       ),
//                       const SizedBox(height: 10),
//                       DropdownButtonFormField<String>(
//                         initialValue: payment,
//                         items: _paymentMethods
//                             .map((p) => DropdownMenuItem(value: p, child: Text(p)))
//                             .toList(),
//                         onChanged: (v) {
//                           if (v != null) {
//                             setModalState(() => payment = v);
//                           }
//                         },
//                         decoration:
//                             const InputDecoration(labelText: 'Payment method'),
//                       ),
//                       const SizedBox(height: 10),
//                       DropdownButtonFormField<RecurringFrequency>(
//                         initialValue: frequency,
//                         items: const [
//                           DropdownMenuItem(
//                             value: RecurringFrequency.weekly,
//                             child: Text('Weekly'),
//                           ),
//                           DropdownMenuItem(
//                             value: RecurringFrequency.monthly,
//                             child: Text('Monthly'),
//                           ),
//                         ],
//                         onChanged: (v) {
//                           if (v != null) {
//                             setModalState(() => frequency = v);
//                           }
//                         },
//                         decoration: const InputDecoration(labelText: 'Frequency'),
//                       ),
//                       const SizedBox(height: 10),
//                       OutlinedButton.icon(
//                         onPressed: () async {
//                           final picked = await showDatePicker(
//                             context: context,
//                             initialDate: startDate,
//                             firstDate: DateTime.now().subtract(const Duration(days: 3650)),
//                             lastDate: DateTime.now().add(const Duration(days: 3650)),
//                           );
//                           if (picked != null) {
//                             setModalState(() => startDate = picked);
//                           }
//                         },
//                         icon: const Icon(Icons.calendar_month_outlined),
//                         label: Text('Start date: ${DateFormat('yyyy-MM-dd').format(startDate)}'),
//                       ),
//                       const SizedBox(height: 10),
//                       TextField(
//                         controller: descCtrl,
//                         decoration:
//                             const InputDecoration(labelText: 'Description (optional)'),
//                       ),
//                       const SizedBox(height: 10),
//                       TextField(
//                         controller: locationCtrl,
//                         decoration:
//                             const InputDecoration(labelText: 'Location (optional)'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                       final nav = Navigator.of(context);
//                     final title = titleCtrl.text.trim();
//                     final amount = double.tryParse(amountCtrl.text.trim());
//                     if (title.isEmpty || amount == null || amount <= 0) {
//                       return;
//                     }
//                     await _db.insertRecurringExpense(
//                       RecurringExpense(
//                         title: title,
//                         amount: amount,
//                         category: category,
//                         paymentMethod: payment,
//                         description: descCtrl.text.trim().isEmpty
//                             ? null
//                             : descCtrl.text.trim(),
//                         location: locationCtrl.text.trim().isEmpty
//                             ? null
//                             : locationCtrl.text.trim(),
//                         startDate: startDate,
//                         frequency: frequency,
//                         nextDueDate: startDate,
//                       ),
//                     );
//                       nav.pop(true);
//                   },
//                   child: const Text('Create'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     if (created == true) {
//       await _loadExpenses();
//     }
//   }

//   /// Deletes a recurring expense template and refreshes the expense list.
//   /// This removes only the template; already-generated individual expenses are preserved.
//   Future<void> _deleteRecurring(RecurringExpense recurringExpense) async {
//     if (recurringExpense.id == null) return;
//     await _db.deleteRecurringExpense(recurringExpense.id!);
//     await _loadExpenses();
//   }

//   Future<Directory> _getExportDirectory() async {
//     Directory? baseDirectory;

//     if (Platform.isAndroid) {
//       final downloadDirectories = await getExternalStorageDirectories(
//         type: StorageDirectory.downloads,
//       );
//       if (downloadDirectories != null && downloadDirectories.isNotEmpty) {
//         baseDirectory = downloadDirectories.first;
//       } else {
//         baseDirectory = await getExternalStorageDirectory();
//       }
//     } else if (Platform.isIOS) {
//       baseDirectory = await getApplicationDocumentsDirectory();
//     } else {
//       baseDirectory = await getDownloadsDirectory();
//       baseDirectory ??= await getApplicationDocumentsDirectory();
//     }

//     final exportDirectory = Directory('${baseDirectory!.path}/Wealtha Exports');
//     if (!await exportDirectory.exists()) {
//       await exportDirectory.create(recursive: true);
//     }
//     return exportDirectory;
//   }

//   /// Exports this month's expenses as a CSV file to a persistent local folder on the device.
//   /// Columns: Date, Title, Category, Payment, Amount, Location, Description.
//   /// File is saved as: expense-report-yyyy-MM.csv
//   /// Shows a snackbar with the file path on successful export.
//   Future<void> _exportMonthlyCsv() async {
//     final now = DateTime.now();
//     final monthExpenses = _expenses
//         .where((e) =>
//             e.date != null && e.date!.year == now.year && e.date!.month == now.month)
//         .toList();
//     if (monthExpenses.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No expenses available for this month.')),
//       );
//       return;
//     }

//     final rows = <List<dynamic>>[
//       ['Date', 'Title', 'Category', 'Payment', 'Amount', 'Location', 'Description'],
//       ...monthExpenses.map(
//         (e) => [
//           e.date?.toIso8601String().split('T').first ?? '',
//           e.title,
//           e.category,
//           e.paymentMethod,
//           e.amount.toStringAsFixed(2),
//           e.location ?? '',
//           e.description ?? '',
//         ],
//       ),
//     ];

//     final csvData = const ListToCsvConverter().convert(rows);
//     final dir = await _getExportDirectory();
//     final path = '${dir.path}/expense-report-${DateFormat('yyyy-MM').format(now)}.csv';
//     await File(path).writeAsString(csvData);

//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('CSV report saved: $path')),
//     );
//   }

//   /// Exports this month's expenses as a PDF report to a persistent local folder on the device.
//   /// PDF contains: total spending, category breakdown table, daily totals table.
//   /// File is saved as: expense-report-yyyy-MM.pdf
//   /// Shows a snackbar with the file path on successful export.
//   Future<void> _exportMonthlyPdf() async {
//     final now = DateTime.now();
//     final monthExpenses = _expenses
//         .where((e) =>
//             e.date != null && e.date!.year == now.year && e.date!.month == now.month)
//         .toList();
//     if (monthExpenses.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No expenses available for this month.')),
//       );
//       return;
//     }

//     final total = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
//     final byCategory = <String, double>{};
//     final byDay = <String, double>{};
//     for (final e in monthExpenses) {
//       byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
//       final day = DateFormat('yyyy-MM-dd').format(e.date!);
//       byDay[day] = (byDay[day] ?? 0) + e.amount;
//     }

//     final doc = pw.Document();
//     doc.addPage(
//       pw.MultiPage(
//         build: (context) => [
//           pw.Text(
//             'Monthly Expense Report - ${DateFormat('MMMM yyyy').format(now)}',
//             style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
//           ),
//           pw.SizedBox(height: 12),
//           pw.Text('Total spending: ${_money(total)}'),
//           pw.SizedBox(height: 12),
//           pw.Text('Category totals', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//           pw.Column(
//             children: byCategory.entries
//                 .map((e) => pw.Row(
//                       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                       children: [pw.Text(e.key), pw.Text(_money(e.value))],
//                     ))
//                 .toList(),
//           ),
//           pw.SizedBox(height: 12),
//           pw.Text('Daily trend', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//           pw.Column(
//             children: byDay.entries
//                 .map((e) => pw.Row(
//                       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                       children: [pw.Text(e.key), pw.Text(_money(e.value))],
//                     ))
//                 .toList(),
//           ),
//         ],
//       ),
//     );

//     final dir = await _getExportDirectory();
//     final path = '${dir.path}/expense-report-${DateFormat('yyyy-MM').format(now)}.pdf';
//     final bytes = await doc.save();
//     await File(path).writeAsBytes(bytes);

//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('PDF report saved: $path')),
//     );
//   }

//   Widget _buildHomeTab(ColorScheme scheme) {
//     final visibleExpenses = _filteredExpenses;

//     return RefreshIndicator(
//       onRefresh: _loadExpenses,
//       child: ListView(
//         padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
//         children: [
//           TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               hintText: 'Search title, description, location...',
//               prefixIcon: const Icon(Icons.search),
//               suffixIcon: IconButton(
//                 tooltip: 'Filter expenses',
//                 onPressed: _openFilters,
//                 icon: const Icon(Icons.tune),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 44,
//                     height: 44,
//                     decoration: BoxDecoration(
//                       color: scheme.primary.withValues(alpha: 0.14),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Icon(Icons.insights_rounded, color: scheme.primary),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Total spending",
//                           style: TextStyle(
//                             color: scheme.onSurfaceVariant,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 250),
//                           transitionBuilder: (child, anim) {
//                             return FadeTransition(
//                               opacity: anim,
//                               child: SlideTransition(
//                                 position: Tween<Offset>(
//                                   begin: const Offset(0, 0.15),
//                                   end: Offset.zero,
//                                 ).animate(anim),
//                                 child: child,
//                               ),
//                             );
//                           },
//                           child: Text(
//                             _money(_total),
//                             key: ValueKey(_total),
//                             style: TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.w900,
//                               color: scheme.onSurface,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 220),
//                     switchInCurve: Curves.easeOut,
//                     switchOutCurve: Curves.easeIn,
//                     transitionBuilder: (child, animation) {
//                       return FadeTransition(
//                         opacity: animation,
//                         child: ScaleTransition(
//                           scale: Tween<double>(
//                             begin: 0.96,
//                             end: 1.0,
//                           ).animate(animation),
//                           child: child,
//                         ),
//                       );
//                     },
//                     child: Container(
//                       key: ValueKey(visibleExpenses.length),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                       child: Text(
//                         '${visibleExpenses.length} items',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w800,
//                           color: scheme.onSurface,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (_monthlyBudget != null && _monthlyBudget! > 0) ...[
//             const SizedBox(height: 10),
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Monthly goal: ${_money(_monthlyBudget!)}',
//                       style: TextStyle(
//                         color: scheme.onSurface,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     LinearProgressIndicator(
//                       value: (_monthlyTotal / _monthlyBudget!).clamp(0, 1),
//                       minHeight: 10,
//                       color: _monthlyTotal > _monthlyBudget!
//                           ? scheme.error
//                           : scheme.primary,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       _monthlyTotal > _monthlyBudget!
//                           ? 'Over budget by ${_money(_monthlyTotal - _monthlyBudget!)}'
//                           : '${_money(_monthlyBudget! - _monthlyTotal)} left this month',
//                       style: TextStyle(
//                         color: _monthlyTotal > _monthlyBudget!
//                             ? scheme.error
//                             : scheme.onSurfaceVariant,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//           const SizedBox(height: 10),
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 250),
//             child: visibleExpenses.isEmpty
//                 ? Padding(
//                     key: const ValueKey("empty"),
//                     padding: const EdgeInsets.only(top: 80),
//                     child: Column(
//                       children: [
//                         Icon(
//                           Icons.receipt_long,
//                           size: 56,
//                           color: scheme.onSurfaceVariant,
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           "No expenses yet",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w800,
//                             color: scheme.onSurface,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           "Tap “Add” to create your first expense.",
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             color: scheme.onSurfaceVariant,
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : Column(
//                     key: const ValueKey("list"),
//                   children: visibleExpenses.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final expense = entry.value;
//                       final animDuration = Duration(
//                         milliseconds: 220 + (index * 35).clamp(0, 280),
//                       );

//                       return TweenAnimationBuilder<double>(
//                         key: ValueKey(
//                           'expense-${expense.id}-$_listAnimationSeed',
//                         ),
//                         duration: animDuration,
//                         curve: Curves.easeOutCubic,
//                         tween: Tween(begin: 0, end: 1),
//                         builder: (context, value, child) {
//                           return Opacity(
//                             opacity: value,
//                             child: Transform.translate(
//                               offset: Offset(0, (1 - value) * 16),
//                               child: child,
//                             ),
//                           );
//                         },
//                         child: Dismissible(
//                           key: ValueKey(expense.id),
//                           direction: DismissDirection.endToStart,
//                           onDismissed: (_) => _deleteExpense(expense),
//                           background: Container(
//                             margin: const EdgeInsets.symmetric(vertical: 6),
//                             padding: const EdgeInsets.symmetric(horizontal: 18),
//                             alignment: Alignment.centerRight,
//                             decoration: BoxDecoration(
//                               color: scheme.errorContainer,
//                               borderRadius: BorderRadius.circular(18),
//                             ),
//                             child: Icon(
//                               Icons.delete,
//                               color: scheme.onErrorContainer,
//                             ),
//                           ),
//                           child: Hero(
//                             tag: 'expense-card-${expense.id}',
//                             child: Material(
//                               color: Colors.transparent,
//                               child: Card(
//                                 margin: const EdgeInsets.symmetric(vertical: 6),
//                                 child: ListTile(
//                                   onTap: () async {
//                                     HapticFeedback.selectionClick();
//                                     final changed = await Navigator.push<bool>(
//                                       context,
//                                       PageRouteBuilder(
//                                         transitionDuration:
//                                             const Duration(milliseconds: 500),
//                                         reverseTransitionDuration:
//                                             const Duration(milliseconds: 400),
//                                         pageBuilder: (
//                                           context,
//                                           animation,
//                                           secondaryAnimation,
//                                         ) {
//                                           return ExpenseDetailPage(
//                                             expense: expense,
//                                           );
//                                         },
//                                         transitionsBuilder: (
//                                           context,
//                                           animation,
//                                           secondaryAnimation,
//                                           child,
//                                         ) {
//                                           return FadeTransition(
//                                             opacity: animation,
//                                             child: child,
//                                           );
//                                         },
//                                       ),
//                                     );
//                                     if (changed == true) {
//                                       await _loadExpenses();
//                                     }
//                                   },
//                                   contentPadding: const EdgeInsets.symmetric(
//                                     horizontal: 14,
//                                     vertical: 8,
//                                   ),
//                                   title: Text(
//                                     expense.title,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.w900,
//                                     ),
//                                   ),
//                                   subtitle: Padding(
//                                     padding: const EdgeInsets.only(top: 6),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Wrap(
//                                           spacing: 8,
//                                           runSpacing: 8,
//                                           children: [
//                                             Container(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                 horizontal: 10,
//                                                 vertical: 6,
//                                               ),
//                                               decoration: BoxDecoration(
//                                                 color: _chipColor(
//                                                   expense.category,
//                                                   scheme,
//                                                 ),
//                                                 borderRadius:
//                                                     BorderRadius.circular(999),
//                                               ),
//                                               child: Text(
//                                                 expense.category,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.w800,
//                                                   color: scheme.onSurface,
//                                                 ),
//                                               ),
//                                             ),
//                                             Container(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                 horizontal: 10,
//                                                 vertical: 6,
//                                               ),
//                                               decoration: BoxDecoration(
//                                                 color: scheme
//                                                     .surfaceContainerHighest
//                                                     .withValues(alpha: 0.7),
//                                                 borderRadius:
//                                                     BorderRadius.circular(999),
//                                               ),
//                                               child: Text(
//                                                 expense.paymentMethod,
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.w800,
//                                                   color: scheme.onSurface,
//                                                 ),
//                                               ),
//                                             ),
//                                             _buildStatusChip(expense, scheme),
//                                             if (expense.dueDate != null)
//                                               Container(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                   horizontal: 10,
//                                                   vertical: 6,
//                                                 ),
//                                                 decoration: BoxDecoration(
//                                                   color: _isOverdue(expense)
//                                                       ? scheme.errorContainer
//                                                       : scheme.surfaceContainerHighest
//                                                           .withValues(alpha: 0.7),
//                                                   borderRadius:
//                                                       BorderRadius.circular(999),
//                                                 ),
//                                                 child: Text(
//                                                   'Due ${_formatDueDate(expense.dueDate)}',
//                                                   style: TextStyle(
//                                                     fontWeight: FontWeight.w800,
//                                                     color: _isOverdue(expense)
//                                                         ? scheme.onErrorContainer
//                                                         : scheme.onSurface,
//                                                   ),
//                                                 ),
//                                               ),
//                                           ],
//                                         ),
//                                         if (expense.location != null &&
//                                             expense.location!.trim().isNotEmpty)
//                                           Padding(
//                                             padding:
//                                                 const EdgeInsets.only(top: 8),
//                                             child: Row(
//                                               children: [
//                                                 Icon(
//                                                   Icons.location_on_outlined,
//                                                   size: 16,
//                                                   color:
//                                                       scheme.onSurfaceVariant,
//                                                 ),
//                                                 const SizedBox(width: 4),
//                                                 Expanded(
//                                                   child: Text(
//                                                     expense.location!,
//                                                     maxLines: 1,
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                     style: TextStyle(
//                                                       color: scheme
//                                                           .onSurfaceVariant,
//                                                       fontWeight:
//                                                           FontWeight.w600,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                   trailing: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     children: [
//                                       Text(
//                                         _money(expense.amount),
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.w900,
//                                           color: scheme.onSurface,
//                                         ),
//                                       ),
//                                       if (expense.isPaid) ...[
//                                         const SizedBox(height: 4),
//                                         const Icon(
//                                           Icons.check_circle,
//                                           color: Colors.green,
//                                           size: 18,
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCategoriesTab(ColorScheme scheme) {
//     final totalsByCategory = _monthlyByCategory;

//     for (final category in _defaultCategories) {
//       totalsByCategory[category] = totalsByCategory[category] ?? 0;
//     }

//     final entries = totalsByCategory.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return ListView(
//       padding: const EdgeInsets.all(14),
//       children: [
//         Card(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Monthly Budget Goals',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w900,
//                     color: scheme.onSurface,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   _monthlyBudget == null || _monthlyBudget == 0
//                       ? 'No monthly budget set yet.'
//                       : 'Goal: ${_money(_monthlyBudget!)} | Spent: ${_money(_monthlyTotal)}',
//                   style: TextStyle(
//                     color: scheme.onSurfaceVariant,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: _openBudgetDialog,
//                     icon: const Icon(Icons.savings_outlined),
//                     label: const Text('Set Monthly Budget Goals'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Card(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Recurring Expenses',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w900,
//                     color: scheme.onSurface,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton.icon(
//                     onPressed: _openRecurringDialog,
//                     icon: const Icon(Icons.repeat),
//                     label: const Text('Add Recurring Expense'),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 if (_recurringExpenses.isEmpty)
//                   Text(
//                     'No recurring expenses yet.',
//                     style: TextStyle(
//                       color: scheme.onSurfaceVariant,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   )
//                 else
//                   ..._recurringExpenses.map(
//                     (r) => ListTile(
//                       contentPadding: EdgeInsets.zero,
//                       title: Text(
//                         r.title,
//                         style: const TextStyle(fontWeight: FontWeight.w800),
//                       ),
//                       subtitle: Text(
//                         '${r.frequency == RecurringFrequency.monthly ? 'Monthly' : 'Weekly'} • Next: ${DateFormat('yyyy-MM-dd').format(r.nextDueDate)}',
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(_money(r.amount)),
//                           IconButton(
//                             onPressed: () => _deleteRecurring(r),
//                             icon: const Icon(Icons.delete_outline),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Card(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text(
//               'Spending by category (this month)',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w900,
//                 color: scheme.onSurface,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         if (entries.isEmpty)
//           const Padding(
//             padding: EdgeInsets.only(top: 40),
//             child: Center(child: Text("No category data yet")),
//           )
//         else
//           ...entries.map(
//             (entry) => Card(
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: _chipColor(entry.key, scheme),
//                   child: const Icon(Icons.category, color: Colors.black87),
//                 ),
//                 title: Text(
//                   entry.key,
//                   style: const TextStyle(fontWeight: FontWeight.w800),
//                 ),
//                 trailing: Text(
//                   _categoryBudgets.containsKey(entry.key) &&
//                           entry.value > _categoryBudgets[entry.key]!
//                       ? '${_money(entry.value)} (over)'
//                       : _money(entry.value),
//                   style: TextStyle(
//                     fontWeight: FontWeight.w900,
//                     color: _categoryBudgets.containsKey(entry.key) &&
//                             entry.value > _categoryBudgets[entry.key]!
//                         ? scheme.error
//                         : scheme.onSurface,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildProfileTab(ColorScheme scheme) {
//     final user = FirebaseAuth.instance.currentUser;

//     return ListView(
//       padding: const EdgeInsets.all(14),
//       children: [
//         Card(
//           child: Padding(
//             padding: const EdgeInsets.all(18),
//             child: Column(
//               children: [
//                 CircleAvatar(
//                   radius: 34,
//                   backgroundColor: scheme.primary.withValues(alpha: 0.15),
//                   child: Icon(
//                     Icons.person,
//                     size: 34,
//                     color: scheme.primary,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   user?.email ?? "No email",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w800,
//                     color: scheme.onSurface,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Signed in user",
//                   style: TextStyle(
//                     color: scheme.onSurfaceVariant,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Card(
//           child: ListTile(
//             leading: const Icon(Icons.logout),
//             title: const Text("Logout"),
//             onTap: _logout,
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     final pages = [
//       _buildHomeTab(scheme),
//       _buildCategoriesTab(scheme),
//       ChartsPage(expenses: _filteredExpenses),
//       _aiChatPage,
//       _contactPage,
//       _buildProfileTab(scheme),
//     ];

//     final titles = [
//       "Expenses",
//       "Categories",
//       "Charts",
//       "AI Chat",
//       "Contact",
//       "Profile",
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(titles[_selectedIndex]),
//         actions: _selectedIndex == 0
//             ? [
//                 PopupMenuButton<String>(
//                   tooltip: 'Export reports',
//                   onSelected: (value) async {
//                     if (value == 'csv') {
//                       await _exportMonthlyCsv();
//                       return;
//                     }
//                     if (value == 'pdf') {
//                       await _exportMonthlyPdf();
//                     }
//                   },
//                   itemBuilder: (context) => const [
//                     PopupMenuItem(
//                       value: 'csv',
//                       child: Text('Export monthly CSV'),
//                     ),
//                     PopupMenuItem(
//                       value: 'pdf',
//                       child: Text('Export monthly PDF'),
//                     ),
//                   ],
//                   icon: const Icon(Icons.download_outlined),
//                 ),
//               ]
//             : null,
//       ),
//       drawer: Drawer(
//         child: SafeArea(
//           child: Column(
//             children: [
//               UserAccountsDrawerHeader(
//                 accountName: const Text("Expense Tracker"),
//                 accountEmail: Text(
//                   FirebaseAuth.instance.currentUser?.email ?? "No email",
//                 ),
//                 currentAccountPicture: const CircleAvatar(
//                   child: Icon(Icons.person),
//                 ),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.home_outlined),
//                 title: const Text("Home"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   setState(() => _selectedIndex = 0);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.category_outlined),
//                 title: const Text("Categories"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   setState(() => _selectedIndex = 1);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.bar_chart_outlined),
//                 title: const Text("Charts"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   setState(() => _selectedIndex = 2);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.smart_toy_outlined),
//                 title: const Text("AI Chat"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   setState(() => _selectedIndex = 3);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.contact_mail_outlined),
//                 title: const Text("Contact"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   setState(() => _selectedIndex = 4);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.person_outline),
//                 title: const Text("Profile"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   setState(() => _selectedIndex = 5);
//                 },
//               ),
//               const Spacer(),
//               const Divider(),
//               ListTile(
//                 leading: const Icon(Icons.logout),
//                 title: const Text("Logout"),
//                 onTap: () async {
//                   Navigator.pop(context);
//                   await _logout();
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: IndexedStack(
//         index: _selectedIndex,
//         children: pages,
//       ),
//       floatingActionButton: _selectedIndex == 0
//           ? FloatingActionButton.extended(
//               onPressed: _addExpense,
//               icon: const Icon(Icons.add),
//               label: const Text("Add"),
//             )
//           : null,
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _selectedIndex,
//         onDestinationSelected: (index) {
//           HapticFeedback.selectionClick();
//           setState(() => _selectedIndex = index);
//         },
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.home_outlined),
//             selectedIcon: Icon(Icons.home),
//             label: "Home",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.category_outlined),
//             selectedIcon: Icon(Icons.category),
//             label: "Categories",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.bar_chart_outlined),
//             selectedIcon: Icon(Icons.bar_chart),
//             label: "Charts",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.smart_toy_outlined),
//             selectedIcon: Icon(Icons.smart_toy),
//             label: "AI",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.contact_mail_outlined),
//             selectedIcon: Icon(Icons.contact_mail),
//             label: "Contact",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.person_outline),
//             selectedIcon: Icon(Icons.person),
//             label: "Profile",
//           ),
//         ],
//       ),
//     );
//   }
// }


// ONLY showing modified parts for brevity → BUT YOU SAID FULL FILE
// So here is FULL WORKING VERSION ↓↓↓

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'database/expense_database.dart';
import 'models/expense.dart';
import 'add_expense.dart';
import 'expense_detail_page.dart';
import 'contact_page.dart';
import 'charts_page.dart';
import 'ai_chat_page.dart';
import 'financial_news_page.dart';
import 'settings_page.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final ExpenseDatabase _db = ExpenseDatabase.instance;
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _defaultCategories = [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Entertainment',
    'Health',
    'Other',
  ];

  static const List<String> _paymentMethods = [
    'Cash',
    'Debit',
    'Credit',
    'Online',
  ];

  List<Expense> _expenses = [];
  List<RecurringExpense> _recurringExpenses = [];

  String _searchText = '';
  String? _selectedCategoryFilter;
  String? _selectedPaymentFilter;
  DateTimeRange? _selectedDateRange;
  double? _minAmountFilter;
  double? _maxAmountFilter;

  double? _monthlyBudget;
  Map<String, double> _categoryBudgets = {};

  int _listAnimationSeed = 0;
  int _selectedIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final AiChatPage _aiChatPage;
  late final FinancialNewsPage _financialNewsPage;

  @override
  void initState() {
    super.initState();
    _aiChatPage = const AiChatPage();
    _financialNewsPage = const FinancialNewsPage();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });

    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _monthKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }

  List<Expense> get _filteredExpenses {
    return _expenses.where((expense) {
      if (_searchText.isNotEmpty) {
        final text = [
          expense.title,
          expense.description ?? '',
          expense.location ?? '',
          expense.category,
          expense.paymentMethod,
        ].join(' ').toLowerCase();

        if (!text.contains(_searchText)) {
          return false;
        }
      }

      if (_selectedCategoryFilter != null &&
          expense.category != _selectedCategoryFilter) {
        return false;
      }

      if (_selectedPaymentFilter != null &&
          expense.paymentMethod != _selectedPaymentFilter) {
        return false;
      }

      if (_selectedDateRange != null && expense.date != null) {
        final d = DateTime(
          expense.date!.year,
          expense.date!.month,
          expense.date!.day,
        );
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        );
        if (d.isBefore(start) || d.isAfter(end)) {
          return false;
        }
      }

      if (_minAmountFilter != null && expense.amount < _minAmountFilter!) {
        return false;
      }

      if (_maxAmountFilter != null && expense.amount > _maxAmountFilter!) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _loadExpenses() async {
    final generated = await _db.generateDueRecurringExpenses();
    final data = await _db.getExpenses();
    final recurring = await _db.getRecurringExpenses();
    final monthlyBudget = await _db.getMonthlyBudget(_monthKey);
    final categoryBudgets = await _db.getCategoryBudgets(_monthKey);

    if (!mounted) return;

    if (generated > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added $generated recurring expense(s) automatically.',
          ),
        ),
      );
    }

    setState(() {
      _expenses = data;
      _recurringExpenses = recurring;
      _monthlyBudget = monthlyBudget;
      _categoryBudgets = categoryBudgets;
      _listAnimationSeed++;
    });
  }

  double get _monthlyTotal {
    final now = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == now.year &&
              e.date!.month == now.month,
        )
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  Map<String, double> get _monthlyByCategory {
    final now = DateTime.now();
    final totals = <String, double>{};
    for (final expense in _expenses) {
      if (expense.date == null ||
          expense.date!.year != now.year ||
          expense.date!.month != now.month) {
        continue;
      }
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  /// Calculate last month's spending for trend comparison
  double get _lastMonthTotal {
    final now = DateTime.now();
    final lastMonth = now.month == 1 
        ? DateTime(now.year - 1, 12)
        : DateTime(now.year, now.month - 1);
    
    return _expenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == lastMonth.year &&
              e.date!.month == lastMonth.month,
        )
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Calculate trend percentage (negative = less spending, positive = more spending)
  String get _trendPercentage {
    if (_lastMonthTotal == 0 && _monthlyTotal == 0) return "0%";
    if (_lastMonthTotal == 0) return "+∞";
    
    final change = ((_monthlyTotal - _lastMonthTotal) / _lastMonthTotal * 100);
    return change >= 0 
        ? "+${change.toStringAsFixed(1)}%" 
        : "${change.toStringAsFixed(1)}%";
  }

  /// Get remaining days in current month
  int get _remainingDaysInMonth {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return lastDay - now.day + 1;
  }

  double get _budgetDelta {
    if (_monthlyBudget == null || _monthlyBudget! <= 0) return 0;
    return _monthlyBudget! - _monthlyTotal;
  }

  /// Get remaining budget for this month
  double get _remainingBudget {
    if (_monthlyBudget == null || _monthlyBudget! <= 0) return 0;
    return (_monthlyBudget! - _monthlyTotal).clamp(0, _monthlyBudget!);
  }

  ({IconData icon, Color tint, String title, String message})
  _buildBudgetInsight(ColorScheme scheme) {
    if (_monthlyBudget == null || _monthlyBudget! <= 0) {
      return (
        icon: Icons.auto_awesome_rounded,
        tint: scheme.secondary,
        title: 'AI budget note',
        message:
            'Set a monthly budget to unlock smarter pacing tips as you track spending.',
      );
    }

    final progress = _monthlyTotal / _monthlyBudget!;
    final daysLeft = _remainingDaysInMonth;

    if (_budgetDelta < 0) {
      return (
        icon: Icons.warning_amber_rounded,
        tint: scheme.error,
        title: 'Watch your pace',
        message:
            'You are already ${_money(_monthlyTotal - _monthlyBudget!)} over your monthly goal. Pull back on non-essential spending for the rest of the month.',
      );
    }

    if (progress >= 0.85 && daysLeft > 7) {
      return (
        icon: Icons.call_rounded,
        tint: const Color(0xFFB26A00),
        title: 'Close to your limit',
        message:
            'You have used ${(progress * 100).toStringAsFixed(0)}% of your budget with $daysLeft days left. Keep new spending tight so you do not overshoot your goal.',
      );
    }

    if (progress <= 0.45 && daysLeft <= 12) {
      return (
        icon: Icons.verified_rounded,
        tint: scheme.primary,
        title: 'Strong month so far',
        message:
            'You are in a good position right now. Spending is well below your target and you are on track to close the month comfortably.',
      );
    }

    if (progress <= 0.65) {
      return (
        icon: Icons.trending_up_rounded,
        tint: scheme.primary,
        title: 'Healthy start',
        message:
            'You are tracking well against your goal so far. Keep this pace and you should stay inside your monthly budget.',
      );
    }

    return (
      icon: Icons.insights_rounded,
      tint: scheme.secondary,
      title: 'Stay intentional',
      message:
          'You are in range, but the rest of the month matters. Be selective with extras to finish on budget.',
    );
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
        return scheme.primaryContainer.withValues(alpha: 0.75);
      case "entertainment":
        return scheme.secondaryContainer.withValues(alpha: 0.75);
      case "health":
        return scheme.tertiaryContainer.withValues(alpha: 0.75);
      default:
        return scheme.surfaceContainerHighest;
    }
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'No due date';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  bool _isOverdue(Expense expense) {
    if (expense.dueDate == null || expense.isPaid) return false;
    final due = DateTime(
      expense.dueDate!.year,
      expense.dueDate!.month,
      expense.dueDate!.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return due.isBefore(today);
  }

  Widget _buildStatusChip(Expense expense, ColorScheme scheme) {
    final label = expense.isPaid
        ? 'Paid'
        : _isOverdue(expense)
            ? 'Overdue'
            : 'Unpaid';

    final color = expense.isPaid
        ? Colors.green
        : _isOverdue(expense)
            ? scheme.error
            : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Future<void> _addExpense() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => const AddExpensePage(),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    await _loadExpenses();
  }

  Future<void> _deleteExpense(Expense expense) async {
    final removedIndex = _expenses.indexWhere((e) => e.id == expense.id);
    if (removedIndex == -1) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _expenses.removeWhere((e) => e.id == expense.id);
    });

    var isUndo = false;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${expense.title}"'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            isUndo = true;
            if (!mounted) return;
            setState(() {
              _expenses.insert(removedIndex, expense);
            });
          },
        ),
      ),
    );

    await _db.deleteExpense(expense.id!);
    await controller.closed;

    if (isUndo) {
      await _db.insertExpense(
        Expense(
          title: expense.title,
          amount: expense.amount,
          category: expense.category,
          date: expense.date,
          dueDate: expense.dueDate,
          description: expense.description,
          paymentMethod: expense.paymentMethod,
          location: expense.location,
          isPaid: expense.isPaid,
        ),
      );
      await _loadExpenses();
    }
  }

  Future<void> _logout() async {
    HapticFeedback.selectionClick();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _openFilters() async {
    final minCtrl = TextEditingController(
      text: _minAmountFilter?.toStringAsFixed(2) ?? '',
    );
    final maxCtrl = TextEditingController(
      text: _maxAmountFilter?.toStringAsFixed(2) ?? '',
    );
    String? category = _selectedCategoryFilter;
    String? payment = _selectedPaymentFilter;
    DateTimeRange? dateRange = _selectedDateRange;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Wrap(
                runSpacing: 12,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  DropdownButtonFormField<String?>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ..._defaultCategories.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c,
                          child: Text(c),
                        ),
                      ),
                    ],
                    onChanged: (value) => setModalState(() => category = value),
                  ),
                  DropdownButtonFormField<String?>(
                    initialValue: payment,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ..._paymentMethods.map(
                        (p) => DropdownMenuItem<String?>(
                          value: p,
                          child: Text(p),
                        ),
                      ),
                    ],
                    onChanged: (value) => setModalState(() => payment = value),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(now.year - 10),
                              lastDate: DateTime(now.year + 10),
                              initialDateRange: dateRange,
                            );
                            if (picked != null) {
                              setModalState(() => dateRange = picked);
                            }
                          },
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(
                            dateRange == null
                                ? 'Any date'
                                : '${DateFormat('MMM d').format(dateRange!.start)} - ${DateFormat('MMM d').format(dateRange!.end)}',
                          ),
                        ),
                      ),
                      if (dateRange != null)
                        IconButton(
                          onPressed: () => setModalState(() => dateRange = null),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Min amount',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Max amount',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategoryFilter = null;
                              _selectedPaymentFilter = null;
                              _selectedDateRange = null;
                              _minAmountFilter = null;
                              _maxAmountFilter = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategoryFilter = category;
                              _selectedPaymentFilter = payment;
                              _selectedDateRange = dateRange;
                              _minAmountFilter =
                                  double.tryParse(minCtrl.text.trim());
                              _maxAmountFilter =
                                  double.tryParse(maxCtrl.text.trim());
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openBudgetDialog() async {
    final totalCtrl = TextEditingController(
      text: _monthlyBudget?.toStringAsFixed(2) ?? '',
    );
    final categoryControllers = {
      for (final category in _defaultCategories)
        category: TextEditingController(
          text: _categoryBudgets[category]?.toStringAsFixed(2) ?? '',
        ),
    };

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Monthly Budget Goals'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: totalCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Overall monthly budget',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._defaultCategories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: categoryControllers[category],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: '$category budget (optional)',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final total = double.tryParse(totalCtrl.text.trim()) ?? 0;
                final perCategory = <String, double>{};
                for (final entry in categoryControllers.entries) {
                  final value = double.tryParse(entry.value.text.trim());
                  if (value != null && value > 0) {
                    perCategory[entry.key] = value;
                  }
                }
                await _db.upsertMonthlyBudget(
                  monthKey: _monthKey,
                  amount: total,
                  categoryBudgets: perCategory,
                );
                nav.pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await _loadExpenses();
    }
  }

  Future<void> _openRecurringDialog() async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String category = _defaultCategories.first;
    String payment = _paymentMethods[1];
    RecurringFrequency frequency = RecurringFrequency.monthly;
    DateTime startDate = DateTime.now();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add Recurring Expense'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Amount'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        items: _defaultCategories
                            .map(
                              (c) =>
                                  DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => category = v);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: payment,
                        items: _paymentMethods
                            .map(
                              (p) =>
                                  DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => payment = v);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Payment method',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<RecurringFrequency>(
                        initialValue: frequency,
                        items: const [
                          DropdownMenuItem(
                            value: RecurringFrequency.weekly,
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: RecurringFrequency.monthly,
                            child: Text('Monthly'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => frequency = v);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 3650),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (picked != null) {
                            setModalState(() => startDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          'Start date: ${DateFormat('yyyy-MM-dd').format(startDate)}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: locationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Location (optional)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final title = titleCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (title.isEmpty || amount == null || amount <= 0) {
                      return;
                    }
                    await _db.insertRecurringExpense(
                      RecurringExpense(
                        title: title,
                        amount: amount,
                        category: category,
                        paymentMethod: payment,
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        location: locationCtrl.text.trim().isEmpty
                            ? null
                            : locationCtrl.text.trim(),
                        startDate: startDate,
                        frequency: frequency,
                        nextDueDate: startDate,
                      ),
                    );
                    nav.pop(true);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true) {
      await _loadExpenses();
    }
  }

  Future<void> _deleteRecurring(RecurringExpense recurringExpense) async {
    if (recurringExpense.id == null) return;
    await _db.deleteRecurringExpense(recurringExpense.id!);
    await _loadExpenses();
  }

  /// Get the Downloads directory for saving exports.
  /// Uses getDownloadsDirectory() which works across all platforms:
  /// - Android: /storage/emulated/0/Download/
  /// - iOS: Documents folder (with Files app visibility via Info.plist)
  /// - macOS/Windows/Linux: System Downloads folder
  Future<Directory> _getExportDirectory() async {
    try {
      // Try to get the system Downloads directory first (works on all platforms)
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir != null) {
        final exportDirectory =
            Directory('${downloadDir.path}/Wealtha Exports');
        if (!await exportDirectory.exists()) {
          await exportDirectory.create(recursive: true);
        }
        return exportDirectory;
      }
    } catch (e) {
      debugPrint('Error getting Downloads directory: $e');
    }

    // Fallback: use application documents directory if Downloads unavailable
    final appDir = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory('${appDir.path}/Wealtha Exports');
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }
    return exportDirectory;
  }

  Future<void> _showCsvPreview(String path, String fileName) async {
    final rawCsv = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(rawCsv);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) {
          final headers = rows.isNotEmpty
              ? rows.first.map((h) => h.toString()).toList()
              : <String>[];
          final dataRows = rows.length > 1 ? rows.sublist(1) : <List<dynamic>>[];
          return Scaffold(
            appBar: AppBar(
              title: Text(fileName, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share',
                  onPressed: () async {
                    await SharePlus.instance.share(
                      ShareParams(files: [XFile(path)], subject: fileName),
                    );
                  },
                ),
              ],
            ),
            body: dataRows.isEmpty
                ? const Center(child: Text('No data rows found.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        columns: headers
                            .map((h) => DataColumn(
                                  label: Text(
                                    h,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ))
                            .toList(),
                        rows: dataRows
                            .map(
                              (row) => DataRow(
                                cells: List.generate(
                                  headers.length,
                                  (i) => DataCell(
                                    Text(i < row.length
                                        ? row[i].toString()
                                        : ''),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _showExportResultSheet({
    required String label,
    required String path,
  }) async {
    if (!mounted) return;

    final file = File(path);
    final directoryPath = file.parent.path;
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : path;
    final isCsv = path.toLowerCase().endsWith('.csv');

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label saved',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fileName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Open File'),
                  subtitle: const Text('Preview the exported report now'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    if (isCsv) {
                      await _showCsvPreview(path, fileName);
                    } else {
                      await _openExportTarget(path, 'Could not open the file.');
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share'),
                  subtitle: const Text('Send the report to another app'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(path)],
                        subject: '$label from Wealtha',
                        text: 'Sharing $fileName from Wealtha.',
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('Open Folder'),
                  subtitle: const Text('Jump to the export location'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _openExportTarget(
                      directoryPath,
                      'Could not open the export folder on this device.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openExportTarget(String targetPath, String fallbackMessage) async {
    try {
      final result = await OpenFile.open(targetPath);
      if (!mounted) return;
      if (result.type == ResultType.done) {
        return;
      }

      // If opening the file directly failed and it's a file (not a directory),
      // fall back to the system share sheet so the user can still access it.
      final isFile = await File(targetPath).exists();
      if (isFile) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(targetPath)], text: 'Exported from Wealtha'),
        );
        return;
      }

      await _copyPathAndNotify(
        targetPath,
        result.message.isNotEmpty ? result.message : fallbackMessage,
      );
    } on MissingPluginException {
      if (!mounted) return;
      await _copyPathAndNotify(
        targetPath,
        'This action needs a full app restart after the new plugin install. The path was copied for now.',
      );
    } catch (_) {
      if (!mounted) return;
      await _copyPathAndNotify(targetPath, fallbackMessage);
    }
  }

  Future<void> _copyPathAndNotify(String targetPath, String message) async {
    await Clipboard.setData(ClipboardData(text: targetPath));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message Path copied to clipboard.')),
    );
  }

  Future<void> _exportMonthlyCsv() async {
    final now = DateTime.now();
    final monthExpenses = _expenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == now.year &&
              e.date!.month == now.month,
        )
        .toList();

    if (monthExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses available for this month.')),
      );
      return;
    }

    final rows = <List<dynamic>>[
      ['Date', 'Title', 'Category', 'Payment', 'Amount', 'Location', 'Description'],
      ...monthExpenses.map(
        (e) => [
          e.date?.toIso8601String().split('T').first ?? '',
          e.title,
          e.category,
          e.paymentMethod,
          e.amount.toStringAsFixed(2),
          e.location ?? '',
          e.description ?? '',
        ],
      ),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await _getExportDirectory();
    final path =
        '${dir.path}/expense-report-${DateFormat('yyyy-MM').format(now)}.csv';
    await File(path).writeAsString(csvData);

    await _showExportResultSheet(label: 'CSV report', path: path);
  }

  Future<void> _exportMonthlyPdf() async {
    final now = DateTime.now();
    final monthExpenses = _expenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == now.year &&
              e.date!.month == now.month,
        )
        .toList();

    if (monthExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses available for this month.')),
      );
      return;
    }

    final total = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final byCategory = <String, double>{};
    final byDay = <String, double>{};

    for (final e in monthExpenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
      final day = DateFormat('yyyy-MM-dd').format(e.date!);
      byDay[day] = (byDay[day] ?? 0) + e.amount;
    }

    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
      ),
    );
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Monthly Expense Report - ${DateFormat('MMMM yyyy').format(now)}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Total spending: ${_money(total)}'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Category totals',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Column(
            children: byCategory.entries
                .map(
                  (e) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [pw.Text(e.key), pw.Text(_money(e.value))],
                  ),
                )
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Daily trend',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Column(
            children: byDay.entries
                .map(
                  (e) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [pw.Text(e.key), pw.Text(_money(e.value))],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );

    final dir = await _getExportDirectory();
    final path =
        '${dir.path}/expense-report-${DateFormat('yyyy-MM').format(now)}.pdf';
    final bytes = await doc.save();
    await File(path).writeAsBytes(bytes);

    await _showExportResultSheet(label: 'PDF report', path: path);
  }

  Widget _buildHomeTab(ColorScheme scheme) {
    final visibleExpenses = _filteredExpenses;

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search title, description, location...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Filter expenses',
                onPressed: _openFilters,
                icon: const Icon(Icons.tune),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Premium Spending Card with Gradient & Trend
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  scheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "This Month's Spending",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _monthlyTotal > _lastMonthTotal
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 14,
                              color: _monthlyTotal > _lastMonthTotal
                                  ? Colors.red[300]
                                  : Colors.green[300],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _trendPercentage,
                              style: TextStyle(
                                color: _monthlyTotal > _lastMonthTotal
                                    ? Colors.red[300]
                                    : Colors.green[300],
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) {
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _money(_monthlyTotal),
                      key: ValueKey(_monthlyTotal),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Budget Goal",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _monthlyBudget != null && _monthlyBudget! > 0
                                  ? _money(_monthlyBudget!)
                                  : "Not set",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Remaining",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _monthlyBudget != null && _monthlyBudget! > 0
                                  ? _money(_remainingBudget)
                                  : "—",
                              style: TextStyle(
                                color: _remainingBudget < 0 ? Colors.red[200] : Colors.green[200],
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final insight = _buildBudgetInsight(scheme);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: insight.tint.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: insight.tint.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: insight.tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        insight.icon,
                        color: insight.tint,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                insight.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: insight.tint.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'AI tip',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: insight.tint,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            insight.message,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Quick Stats - 3 mini cards
          Row(
            children: [
              // Stat 1: Monthly Spending
              Expanded(
                child: _buildQuickStatCard(
                  scheme: scheme,
                  icon: Icons.trending_down_rounded,
                  label: "Spent",
                  value: _money(_monthlyTotal),
                  color: scheme.error,
                ),
              ),
              const SizedBox(width: 10),
              // Stat 2: Budget Goal
              Expanded(
                child: _buildQuickStatCard(
                  scheme: scheme,
                  icon: Icons.track_changes_rounded,
                  label: "Goal",
                  value: _monthlyBudget != null && _monthlyBudget! > 0
                      ? _money(_monthlyBudget!)
                      : "—",
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              // Stat 3: Days Remaining
              Expanded(
                child: _buildQuickStatCard(
                  scheme: scheme,
                  icon: Icons.calendar_today_rounded,
                  label: "Days Left",
                  value: "${_remainingDaysInMonth}d",
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: visibleExpenses.isEmpty
                ? Padding(
                    key: const ValueKey("empty"),
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.trending_up_rounded,
                            size: 48,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Start Tracking Your Money 💸",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Every dollar counts toward your wealth goals.\nAdd your first expense to begin building wealth.",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
                    children: visibleExpenses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final expense = entry.value;
                      final animDuration = Duration(
                        milliseconds: 220 + (index * 35).clamp(0, 280),
                      );

                      return TweenAnimationBuilder<double>(
                        key: ValueKey(
                          'expense-${expense.id}-$_listAnimationSeed',
                        ),
                        duration: animDuration,
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 16),
                              child: child,
                            ),
                          );
                        },
                        child: Dismissible(
                          key: ValueKey(expense.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteExpense(expense),
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.delete,
                              color: scheme.onErrorContainer,
                            ),
                          ),
                          child: Hero(
                            tag: 'expense-card-${expense.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  onTap: () async {
                                    HapticFeedback.selectionClick();
                                    final changed = await Navigator.push<bool>(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration:
                                            const Duration(milliseconds: 500),
                                        reverseTransitionDuration:
                                            const Duration(milliseconds: 400),
                                        pageBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) {
                                          return ExpenseDetailPage(
                                            expense: expense,
                                          );
                                        },
                                        transitionsBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                    if (changed == true) {
                                      await _loadExpenses();
                                    }
                                  },
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  title: Text(
                                    expense.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _chipColor(
                                                  expense.category,
                                                  scheme,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: scheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.7),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                expense.paymentMethod,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: scheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            _buildStatusChip(expense, scheme),
                                            if (expense.dueDate != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _isOverdue(expense)
                                                      ? scheme.errorContainer
                                                      : scheme
                                                          .surfaceContainerHighest
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  'Due ${_formatDueDate(expense.dueDate)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: _isOverdue(expense)
                                                        ? scheme
                                                            .onErrorContainer
                                                        : scheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (expense.location != null &&
                                            expense.location!.trim().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 16,
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    expense.location!,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                                      if (expense.isPaid) ...[
                                        const SizedBox(height: 4),
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 18,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(ColorScheme scheme) {
    final totalsByCategory = _monthlyByCategory;

    for (final category in _defaultCategories) {
      totalsByCategory[category] = totalsByCategory[category] ?? 0;
    }

    final entries = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Budget Goals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _monthlyBudget == null || _monthlyBudget == 0
                      ? 'No monthly budget set yet.'
                      : 'Goal: ${_money(_monthlyBudget!)} | Spent: ${_money(_monthlyTotal)}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openBudgetDialog,
                    icon: const Icon(Icons.savings_outlined),
                    label: const Text('Set Monthly Budget Goals'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recurring Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openRecurringDialog,
                    icon: const Icon(Icons.repeat),
                    label: const Text('Add Recurring Expense'),
                  ),
                ),
                const SizedBox(height: 10),
                if (_recurringExpenses.isEmpty)
                  Text(
                    'No recurring expenses yet.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  ..._recurringExpenses.map(
                    (r) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        r.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${r.frequency == RecurringFrequency.monthly ? 'Monthly' : 'Weekly'} • Next: ${DateFormat('yyyy-MM-dd').format(r.nextDueDate)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_money(r.amount)),
                          IconButton(
                            onPressed: () => _deleteRecurring(r),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Spending by category (this month)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text("No category data yet")),
          )
        else
          ...entries.map(
            (entry) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _chipColor(entry.key, scheme),
                  child: const Icon(Icons.category, color: Colors.black87),
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: Text(
                  _categoryBudgets.containsKey(entry.key) &&
                          entry.value > _categoryBudgets[entry.key]!
                      ? '${_money(entry.value)} (over)'
                      : _money(entry.value),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _categoryBudgets.containsKey(entry.key) &&
                            entry.value > _categoryBudgets[entry.key]!
                        ? scheme.error
                        : scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

Widget _buildProfileTab(ColorScheme scheme) {
  final user = FirebaseAuth.instance.currentUser;

  return ListView(
    padding: const EdgeInsets.all(14),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: scheme.primary.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person,
                  size: 34,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.email ?? "No email",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Signed in user",
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),

      Card(
        child: ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text("Settings"),
          subtitle: const Text("Appearance and accessibility"),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
          },
        ),
      ),

      const SizedBox(height: 10),

      Card(
        child: ListTile(
          leading: const Icon(Icons.logout),
          title: const Text("Logout"),
          onTap: _logout,
        ),
      ),
    ],
  );
}

  /// Build personalized header with greeting and user avatar
  Widget _buildHeaderWidget(ColorScheme scheme) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final greeting = _getGreeting();
    
    // Extract first name from email (remove numbers)
    String firstName = "Friend";
    if (user?.email != null) {
      final emailPrefix = user!.email!.split('@').first;
      // Remove trailing numbers and capitalize
      final nameOnly = emailPrefix.replaceAll(RegExp(r'\d+$'), '');
      firstName = nameOnly.isEmpty 
          ? "Friend" 
          : nameOnly[0].toUpperCase() + nameOnly.substring(1);
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Greeting + Avatar on same line
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.primary.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$greeting 👋",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date
          Text(
            DateFormat('MMM d, yyyy').format(now),
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 18) return "Good afternoon";
    return "Good evening";
  }

  /// Build a quick stat card for the dashboard
  Widget _buildQuickStatCard({
    required ColorScheme scheme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final pages = [
      _buildHomeTab(scheme),
      _buildCategoriesTab(scheme),
      ChartsPage(expenses: _filteredExpenses),
      _financialNewsPage,
      _aiChatPage,
      _buildProfileTab(scheme),
    ];

    final titles = [
      "Expenses",
      "Categories",
      "Charts",
      "Financial News",
      "AI Chat",
      "Profile",
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _selectedIndex == 0 ? _buildHeaderWidget(scheme) : Text(titles[_selectedIndex]),
        toolbarHeight: _selectedIndex == 0 ? 78 : 56,
        actions: _selectedIndex == 0
            ? [
                PopupMenuButton<String>(
                  tooltip: 'Export reports',
                  onSelected: (value) async {
                    if (value == 'csv') {
                      await _exportMonthlyCsv();
                      return;
                    }
                    if (value == 'pdf') {
                      await _exportMonthlyPdf();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'csv',
                      child: Text('Export monthly CSV'),
                    ),
                    PopupMenuItem(
                      value: 'pdf',
                      child: Text('Export monthly PDF'),
                    ),
                  ],
                  icon: const Icon(Icons.download_outlined),
                ),
              ]
            : null,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: const Text("Expense Tracker"),
                accountEmail: Text(
                  FirebaseAuth.instance.currentUser?.email ?? "No email",
                ),
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text("Home"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text("Categories"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined),
                title: const Text("Charts"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.newspaper_outlined),
                title: const Text("Financial News"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: const Text("AI Chat"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 4);
                },
              ),
              ListTile(
                leading: const Icon(Icons.contact_mail_outlined),
                title: const Text("Contact"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ContactPage(
                        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Profile"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 5);
                },
              ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () async {
                  Navigator.pop(context);
                  await _logout();
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _addExpense,
              icon: const Icon(Icons.add),
              label: const Text("Add"),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: "Categories",
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: "Charts",
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: "News",
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: "AI",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}