// import 'dart:async';
// import 'dart:io';

// import 'package:csv/csv.dart';
// import 'package:excel/excel.dart' hide Border;
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:latlong2/latlong.dart';

// import 'database/expense_database.dart';
// import 'models/expense.dart';

// class AddExpensePage extends StatefulWidget {
//   final Expense? initialExpense;
//   final bool duplicateMode;

//   const AddExpensePage({
//     super.key,
//     this.initialExpense,
//     this.duplicateMode = false,
//   });

//   @override
//   State<AddExpensePage> createState() => _AddExpensePageState();
// }

// class _AddExpensePageState extends State<AddExpensePage>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();

//   final _titleCtrl = TextEditingController();
//   final _amountCtrl = TextEditingController();
//   final _descCtrl = TextEditingController();
//   final _locationCtrl = TextEditingController();

//   final ImagePicker _imagePicker = ImagePicker();

//   DateTime? _date = DateTime.now();
//   DateTime? _dueDate;
//   bool _isPaid = false;
//   bool _isRecurring = false;
//   RecurringFrequency? _selectedFrequency;

//   final List<String> _categories = const [
//     'Food',
//     'Transport',
//     'Bills',
//     'Shopping',
//     'Entertainment',
//     'Health',
//     'Other',
//   ];

//   final List<String> _paymentMethods = const [
//     'Cash',
//     'Debit',
//     'Credit',
//     'Online',
//   ];

//   String _selectedCategory = 'Food';
//   String _selectedPayment = 'Debit';
//   bool _showDescription = false;

//   bool _isFabOpen = false;
//   late AnimationController _fabController;
//   late Animation<double> _fabAnimation;

//   final MapController _mapController = MapController();
//   LatLng? _locationPoint;
//   bool _isSearchingLocation = false;
//   String? _locationError;

//   bool _isScanningReceipt = false;
//   String? _scannedRawText;

//   bool get _isEditing =>
//       widget.initialExpense != null && widget.duplicateMode == false;

//   @override
//   void initState() {
//     super.initState();

//     _fabController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 220),
//     );
//     _fabAnimation = CurvedAnimation(
//       parent: _fabController,
//       curve: Curves.easeOut,
//     );

//     _recoverLostCameraImage();

//     final initial = widget.initialExpense;
//     if (initial != null) {
//       _titleCtrl.text = initial.title;
//       _amountCtrl.text = initial.amount.toStringAsFixed(2);
//       _descCtrl.text = initial.description ?? '';
//       _locationCtrl.text = initial.location ?? '';
//       _date = initial.date ?? DateTime.now();
//       _dueDate = initial.dueDate;
//       _selectedCategory = _categories.contains(initial.category)
//           ? initial.category
//           : 'Other';
//       _selectedPayment = _paymentMethods.contains(initial.paymentMethod)
//           ? initial.paymentMethod
//           : 'Cash';
//       _showDescription = _descCtrl.text.trim().isNotEmpty;
//       _isPaid = widget.duplicateMode ? false : initial.isPaid;

//       if ((initial.location ?? '').trim().isNotEmpty) {
//         WidgetsBinding.instance.addPostFrameCallback((_) async {
//           await _searchAndSelectLocation(initial.location!);
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _titleCtrl.dispose();
//     _amountCtrl.dispose();
//     _descCtrl.dispose();
//     _locationCtrl.dispose();
//     _fabController.dispose();
//     super.dispose();
//   }

//   void _toggleFab() {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _isFabOpen = !_isFabOpen;
//     });

//     if (_isFabOpen) {
//       _fabController.forward();
//     } else {
//       _fabController.reverse();
//     }
//   }

//   Future<void> _recoverLostCameraImage() async {
//     try {
//       final LostDataResponse response = await _imagePicker.retrieveLostData();

//       if (response.isEmpty) return;

//       if (response.files != null && response.files!.isNotEmpty) {
//         await _processPickedReceiptFile(response.files!.first);
//         return;
//       }

//       if (response.file != null) {
//         await _processPickedReceiptFile(response.file!);
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to recover camera image: $e')),
//       );
//     }
//   }

//   Future<void> _processPickedReceiptFile(XFile pickedFile) async {
//     TextRecognizer? textRecognizer;

//     try {
//       if (!mounted) return;

//       setState(() {
//         _isScanningReceipt = true;
//         _scannedRawText = null;
//       });

//       final inputImage = InputImage.fromFilePath(pickedFile.path);
//       textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

//       final recognizedText = await textRecognizer.processImage(inputImage);
//       final rebuiltText = _buildReadableReceiptText(recognizedText);

//       if (!mounted) return;
//       setState(() {
//         _scannedRawText = rebuiltText;
//       });

//       await _extractExpenseFieldsFromRecognizedText(recognizedText);

//       if (!mounted) return;
//       HapticFeedback.mediumImpact();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             rebuiltText.isEmpty
//                 ? 'Scan finished, but no text was detected'
//                 : 'Receipt scanned successfully',
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       HapticFeedback.heavyImpact();
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
//     } finally {
//       try {
//         await textRecognizer?.close();
//       } catch (_) {}

//       if (mounted) {
//         setState(() {
//           _isScanningReceipt = false;
//         });
//       }
//     }
//   }

//   Future<void> _onCameraTap() async {
//     if (_isScanningReceipt) return;

//     HapticFeedback.lightImpact();

//     if (mounted) {
//       setState(() {
//         _isFabOpen = false;
//       });
//     }
//     _fabController.reverse();

//     try {
//       final XFile? pickedFile = await _imagePicker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 70,
//         maxWidth: 900,
//         maxHeight: 900,
//         preferredCameraDevice: CameraDevice.rear,
//       );

//       if (pickedFile == null) return;
//       await Future.delayed(const Duration(milliseconds: 300));
//       await _processPickedReceiptFile(pickedFile);
//     } catch (e) {
//       if (!mounted) return;
//       HapticFeedback.heavyImpact();
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
//     }
//   }

//   Future<void> _onFileTap() async {
//     HapticFeedback.lightImpact();

//     setState(() {
//       _isFabOpen = false;
//     });
//     _fabController.reverse();

//     await _importExpenseFile();
//   }

//   Future<void> _importExpenseFile() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['csv', 'xlsx', 'xls'],
//         allowMultiple: false,
//       );

//       if (result == null || result.files.isEmpty) return;

//       final picked = result.files.single;
//       final path = picked.path;
//       if (path == null) {
//         throw Exception('Unable to read selected file path.');
//       }

//       final extension = (picked.extension ?? '').toLowerCase();
//       final file = File(path);

//       List<Map<String, dynamic>> rows = [];

//       if (extension == 'csv') {
//         final input = await file.readAsString();
//         final csvTable = const CsvToListConverter().convert(input);

//         if (csvTable.isEmpty) {
//           throw Exception('CSV file is empty.');
//         }

//         final headers = csvTable.first
//             .map((e) => e.toString().trim().toLowerCase())
//             .toList();

//         for (int i = 1; i < csvTable.length; i++) {
//           final row = csvTable[i];
//           if (_isRowCompletelyEmpty(row)) continue;

//           final data = <String, dynamic>{};
//           for (int j = 0; j < headers.length && j < row.length; j++) {
//             data[headers[j]] = row[j];
//           }

//           if (!_looksLikeExpenseRow(data)) continue;
//           rows.add(data);
//         }
//       } else if (extension == 'xlsx' || extension == 'xls') {
//         final bytes = await file.readAsBytes();
//         final excel = Excel.decodeBytes(bytes);

//         if (excel.tables.isEmpty) {
//           throw Exception('Excel file has no sheets.');
//         }

//         final sheet = excel.tables.values.first;
//         if (sheet.rows.isEmpty) {
//           throw Exception('Excel sheet is empty.');
//         }

//         final headers = sheet.rows.first
//             .map((cell) => cell?.value.toString().trim().toLowerCase() ?? '')
//             .toList();

//         for (int i = 1; i < sheet.rows.length; i++) {
//           final row = sheet.rows[i];
//           if (_isExcelRowEmpty(row)) continue;

//           final data = <String, dynamic>{};
//           for (int j = 0; j < headers.length && j < row.length; j++) {
//             data[headers[j]] = row[j]?.value;
//           }

//           if (!_looksLikeExpenseRow(data)) continue;
//           rows.add(data);
//         }
//       } else {
//         throw Exception('Unsupported file type.');
//       }

//       final toImport = <Expense>[];

//       for (final row in rows) {
//         final amount = _parseAmount(
//           _readAny(row, const [
//             'amount',
//             'cost',
//             'price',
//             'expense',
//             r'$',
//             'total',
//           ]),
//         );

//         if (amount == null || amount <= 0) continue;

//         final parsedDate = _parseDate(
//           _readAny(row, const ['date', 'expense date', 'day']),
//         );

//         final description = _stringValue(
//           _readAny(row, const ['description', 'details', 'note']),
//         );

//         final title =
//             _stringValue(_readAny(row, const ['title', 'name', 'item'])) ??
//             description ??
//             'Imported Expense';

//         final categoryText = _stringValue(
//           _readAny(row, const ['category', 'type']),
//         );

//         final paymentText = _stringValue(
//           _readAny(row, const ['payment', 'payment method', 'method']),
//         );

//         final locationText = _stringValue(
//           _readAny(row, const ['location', 'place', 'store']),
//         );

//         final combinedText = [
//           title,
//           if (description != null) description,
//           if (locationText != null) locationText,
//           if (categoryText != null) categoryText,
//         ].join('\n');

//         toImport.add(
//           Expense(
//             title: title,
//             amount: amount,
//             category:
//                 _normalizeCategory(categoryText) ??
//                 _inferCategoryFromReceipt(combinedText),
//             date: parsedDate ?? DateTime.now(),
//             dueDate: null,
//             description: description,
//             paymentMethod: _normalizePaymentMethod(paymentText) ?? 'Cash',
//             location: locationText,
//             isPaid: false,
//           ),
//         );
//       }

//       await ExpenseDatabase.instance.insertExpenses(toImport);
//       final importedCount = toImport.length;

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             importedCount > 0
//                 ? 'Imported $importedCount expense(s)'
//                 : 'No valid expense rows found in file',
//           ),
//         ),
//       );

//       if (importedCount > 0) {
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
//     }
//   }

//   bool _isRowCompletelyEmpty(List<dynamic> row) {
//     for (final cell in row) {
//       if (cell != null && cell.toString().trim().isNotEmpty) {
//         return false;
//       }
//     }
//     return true;
//   }

//   bool _isExcelRowEmpty(List<Data?> row) {
//     for (final cell in row) {
//       if (cell?.value != null && cell!.value.toString().trim().isNotEmpty) {
//         return false;
//       }
//     }
//     return true;
//   }

//   bool _looksLikeExpenseRow(Map<String, dynamic> row) {
//     final joined = row.values
//         .map((e) => e?.toString().toLowerCase() ?? '')
//         .join(' ');

//     if (joined.contains('total expenses') ||
//         joined.contains('grand total') ||
//         joined.contains('subtotal')) {
//       return false;
//     }
//     return true;
//   }

//   dynamic _readAny(Map<String, dynamic> row, List<String> possibleKeys) {
//     for (final key in possibleKeys) {
//       for (final existingKey in row.keys) {
//         if (existingKey.trim().toLowerCase() == key.trim().toLowerCase()) {
//           return row[existingKey];
//         }
//       }
//     }
//     return null;
//   }

//   String? _stringValue(dynamic value) {
//     if (value == null) return null;
//     final text = value.toString().trim();
//     if (text.isEmpty) return null;
//     return text;
//   }

//   double? _parseAmount(dynamic value) {
//     if (value == null) return null;

//     final raw = value.toString().trim();
//     if (raw.isEmpty) return null;

//     final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
//     if (cleaned.isEmpty) return null;

//     return double.tryParse(cleaned);
//   }

//   DateTime? _parseDate(dynamic value) {
//     if (value == null) return null;
//     if (value is DateTime) return value;

//     var raw = value.toString().trim();
//     if (raw.isEmpty) return null;

//     raw = raw.replaceAll('O', '0').replaceAll('o', '0');

//     final direct = DateTime.tryParse(raw);
//     if (direct != null) return direct;

//     final match = RegExp(
//       r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{2}\.\d{2}\.\d{2,4}|\d{4}-\d{2}-\d{2})',
//     ).firstMatch(raw);

//     final dateOnly = match != null ? match.group(0)! : raw;

//     final slashParts = dateOnly.split('/');
//     if (slashParts.length == 3) {
//       final month = int.tryParse(slashParts[0]);
//       final day = int.tryParse(slashParts[1]);
//       var year = int.tryParse(slashParts[2]);

//       if (month != null && day != null && year != null) {
//         if (year < 100) {
//           year += (year >= 70) ? 1900 : 2000;
//         }
//         if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
//           return DateTime(year, month, day);
//         }
//       }
//     }

//     final dashParts = dateOnly.split('-');
//     if (dashParts.length == 3) {
//       final y1 = int.tryParse(dashParts[0]);
//       final m1 = int.tryParse(dashParts[1]);
//       final d1 = int.tryParse(dashParts[2]);

//       if (y1 != null && m1 != null && d1 != null) {
//         if (y1 > 999 && m1 >= 1 && m1 <= 12 && d1 >= 1 && d1 <= 31) {
//           return DateTime(y1, m1, d1);
//         }
//       }

//       final day = int.tryParse(dashParts[0]);
//       final month = int.tryParse(dashParts[1]);
//       var year = int.tryParse(dashParts[2]);

//       if (day != null && month != null && year != null) {
//         if (year < 100) {
//           year += (year >= 70) ? 1900 : 2000;
//         }
//         if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
//           return DateTime(year, month, day);
//         }
//       }
//     }

//     final dotParts = dateOnly.split('.');
//     if (dotParts.length == 3) {
//       final day = int.tryParse(dotParts[0]);
//       final month = int.tryParse(dotParts[1]);
//       var year = int.tryParse(dotParts[2]);

//       if (day != null && month != null && year != null) {
//         if (year < 100) {
//           year += (year >= 70) ? 1900 : 2000;
//         }
//         if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
//           return DateTime(year, month, day);
//         }
//       }
//     }

//     return null;
//   }

//   String? _normalizeCategory(dynamic value) {
//     final text = _stringValue(value);
//     if (text == null) return null;

//     for (final category in _categories) {
//       if (category.toLowerCase() == text.toLowerCase()) {
//         return category;
//       }
//     }

//     return text;
//   }

//   String? _normalizePaymentMethod(dynamic value) {
//     final text = _stringValue(value);
//     if (text == null) return null;

//     for (final method in _paymentMethods) {
//       if (method.toLowerCase() == text.toLowerCase()) {
//         return method;
//       }
//     }

//     final lower = text.toLowerCase();
//     if (lower.contains('debit')) return 'Debit';
//     if (lower.contains('credit')) return 'Credit';
//     if (lower.contains('cash')) return 'Cash';
//     if (lower.contains('online')) return 'Online';

//     return text;
//   }

//   String _normalizeReceiptText(String text) {
//     return text
//         .replaceAll('O', '0')
//         .replaceAll('o', '0')
//         .replaceAll('SFr', 'CHF');
//   }

//   List<String> _extractOrderedLinesFromRecognizedText(RecognizedText text) {
//     final lines = <Map<String, dynamic>>[];

//     for (final block in text.blocks) {
//       for (final line in block.lines) {
//         final raw = line.text.trim();
//         if (raw.isEmpty) continue;

//         lines.add({
//           'text': raw,
//           'top': line.boundingBox.top.toDouble(),
//           'left': line.boundingBox.left.toDouble(),
//         });
//       }
//     }

//     if (lines.isEmpty) return [];

//     lines.sort((a, b) {
//       final double topA = a['top'] as double;
//       final double topB = b['top'] as double;
//       final double leftA = a['left'] as double;
//       final double leftB = b['left'] as double;

//       final double topDiff = (topA - topB).abs();
//       if (topDiff <= 14) {
//         return leftA.compareTo(leftB);
//       }
//       return topA.compareTo(topB);
//     });

//     return lines.map((e) => e['text'] as String).toList();
//   }

//   String _buildReadableReceiptText(RecognizedText text) {
//     final orderedLines = _extractOrderedLinesFromRecognizedText(text);
//     return orderedLines.join('\n').trim();
//   }

//   bool _looksLikeHeaderStopLine(String line) {
//     final lower = line.toLowerCase().trim();

//     return lower.contains('date/time') ||
//         lower.startsWith('date') ||
//         lower.contains('receipt #') ||
//         lower.contains('receipt#:') ||
//         lower.contains('station #') ||
//         lower.contains('cashier') ||
//         lower == 'sale' ||
//         lower == 'qty' ||
//         lower.contains('qty ') ||
//         lower == 'product' ||
//         lower == 'price' ||
//         lower == 'sum' ||
//         (lower.contains('qty') &&
//             lower.contains('product') &&
//             (lower.contains('price') || lower.contains('sum')));
//   }

//   bool _isBadMerchantLine(String line) {
//     final lower = line.toLowerCase().trim();

//     if (lower.isEmpty) return true;

//     if (lower.contains('receipt') ||
//         lower.contains('invoice') ||
//         lower == 'sale' ||
//         lower == 'qty' ||
//         lower == 'product' ||
//         lower == 'price' ||
//         lower == 'sum' ||
//         lower.contains('date') ||
//         lower.contains('time') ||
//         lower.contains('station') ||
//         lower.contains('cashier') ||
//         lower.contains('hst') ||
//         lower.contains('gst') ||
//         lower.contains('tax') ||
//         lower.contains('tel') ||
//         lower.contains('fax') ||
//         lower.contains('www') ||
//         lower.contains('.com') ||
//         lower.contains('card transaction record')) {
//       return true;
//     }

//     if (RegExp(r'^\d[\d/\-:. ]+$').hasMatch(lower)) return true;
//     if (RegExp(r'^\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}$').hasMatch(lower)) {
//       return true;
//     }
//     if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(lower)) {
//       return true;
//     }

//     return false;
//   }

//   String _cleanMerchantTitle(String value) {
//     var text = value.trim();
//     if (text.isEmpty) return text;

//     text = text.replaceAll(RegExp(r'\s+'), ' ');
//     text = text.replaceAll(
//       RegExp(r'(?<=\D)0(?=\D)|(?<=\b)0(?=\D)|(?<=\D)0(?=\b)'),
//       'O',
//     );

//     if (text == text.toUpperCase()) {
//       return text
//           .split(RegExp(r'\s+'))
//           .where((w) => w.isNotEmpty)
//           .map((w) {
//             if (w.length == 1) return w.toUpperCase();
//             return w[0].toUpperCase() + w.substring(1).toLowerCase();
//           })
//           .join(' ');
//     }

//     return text;
//   }

//   String? _extractBestTitleFromRecognizedText(RecognizedText text) {
//     final lines = _extractOrderedLinesFromRecognizedText(text);
//     if (lines.isEmpty) return null;

//     final topLines = lines.take(10).toList();

//     final headerLines = <String>[];
//     for (final line in topLines) {
//       if (_looksLikeHeaderStopLine(line)) break;
//       headerLines.add(line);
//     }

//     bool looksLikeAddress(String line) {
//       final lower = line.toLowerCase();
//       return RegExp(r'\d').hasMatch(line) &&
//           (lower.contains('avenue') ||
//               lower.contains('street') ||
//               lower.contains('road') ||
//               lower.contains('drive') ||
//               lower.contains('blvd') ||
//               lower.contains('ont') ||
//               lower.contains('scarborough'));
//     }

//     int scoreLine(String line, int index) {
//       int score = 0;
//       final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
//       final digits = RegExp(r'\d').allMatches(line).length;

//       if (index == 0) score += 40;
//       if (index == 1) score += 25;
//       if (index == 2) score += 12;

//       if (letters >= 5) score += 18;
//       if (digits == 0) score += 12;
//       if (line.length >= 4 && line.length <= 30) score += 14;
//       if (line == line.toUpperCase()) score += 6;
//       if (looksLikeAddress(line)) score -= 35;
//       if (_isBadMerchantLine(line)) score -= 100;

//       return score;
//     }

//     String? bestLine;
//     int bestScore = -9999;

//     for (int i = 0; i < headerLines.length; i++) {
//       final line = headerLines[i];

//       final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
//       final digits = RegExp(r'\d').allMatches(line).length;

//       if (letters < 3) continue;
//       if (digits > letters) continue;
//       if (_isBadMerchantLine(line)) continue;

//       final score = scoreLine(line, i);
//       if (score > bestScore) {
//         bestScore = score;
//         bestLine = line;
//       }
//     }

//     if (bestLine != null && bestLine.trim().isNotEmpty) {
//       return _cleanMerchantTitle(
//         bestLine.length > 40 ? bestLine.substring(0, 40) : bestLine,
//       );
//     }

//     for (final line in topLines) {
//       if (!_isBadMerchantLine(line)) {
//         return _cleanMerchantTitle(
//           line.length > 40 ? line.substring(0, 40) : line,
//         );
//       }
//     }

//     return _cleanMerchantTitle(
//       lines.first.length > 40 ? lines.first.substring(0, 40) : lines.first,
//     );
//   }

//   double? _tryParseReceiptAmount(String raw) {
//     var cleaned = raw.trim();
//     cleaned = cleaned.replaceAll(RegExp(r'[^0-9,.\-]'), '');

//     if (cleaned.contains(',') && cleaned.contains('.')) {
//       cleaned = cleaned.replaceAll(',', '');
//     } else if (cleaned.contains(',') && !cleaned.contains('.')) {
//       cleaned = cleaned.replaceAll(',', '.');
//     }

//     return double.tryParse(cleaned);
//   }

//   double? _extractBestAmountFromReceipt(String text) {
//     final normalized = _normalizeReceiptText(text);

//     final lines = normalized
//         .split('\n')
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();

//     final amountRegex = RegExp(r'(?<!\d)(\d{1,4}[.,]\d{2})(?!\d)');

//     double? parseLastAmount(String line) {
//       final matches = amountRegex.allMatches(line).toList();
//       if (matches.isEmpty) return null;
//       return _tryParseReceiptAmount(matches.last.group(0)!);
//     }

//     bool containsAny(String line, List<String> keywords) {
//       final lower = line.toLowerCase();
//       return keywords.any((k) => lower.contains(k));
//     }

//     bool containsNone(String line, List<String> keywords) {
//       final lower = line.toLowerCase();
//       return keywords.every((k) => !lower.contains(k));
//     }

//     // 1. Highest-priority labels
//     const priority1 = [
//       'grand total',
//       'amount due',
//       'balance due',
//       'total due',
//       'net total',
//     ];

//     for (final line in lines.reversed) {
//       if (containsAny(line, priority1)) {
//         final parsed = parseLastAmount(line);
//         if (parsed != null && parsed > 0) return parsed;
//       }
//     }

//     // 2. Generic "total" lines, but ignore tax/subtotal-related ones
//     const excludedTotalWords = [
//       'tax',
//       'total tax',
//       'subtotal',
//       'sub total',
//       'hst',
//       'gst',
//       'vat',
//       'tip',
//       'change',
//       'discount',
//       'savings',
//       'refund',
//     ];

//     for (final line in lines.reversed) {
//       final lower = line.toLowerCase();
//       if (lower.contains('total') && containsNone(line, excludedTotalWords)) {
//         final parsed = parseLastAmount(line);
//         if (parsed != null && parsed > 0) return parsed;
//       }
//     }

//     // 3. Look for approved/paid card transaction summaries near the bottom
//     for (final line in lines.reversed.take(12)) {
//       final lower = line.toLowerCase();
//       if ((lower.contains('approved') ||
//               lower.contains('paid') ||
//               lower.contains('debit') ||
//               lower.contains('credit') ||
//               lower.contains('visa') ||
//               lower.contains('mastercard')) &&
//           !lower.contains('card number')) {
//         final parsed = parseLastAmount(line);
//         if (parsed != null && parsed > 0) return parsed;
//       }
//     }

//     // 4. Fallback: collect amounts, ignore obvious non-final values, pick largest reasonable one
//     final candidates = <double>[];

//     for (final line in lines) {
//       final lower = line.toLowerCase();

//       if (lower.contains('tax') ||
//           lower.contains('hst') ||
//           lower.contains('gst') ||
//           lower.contains('vat') ||
//           lower.contains('change') ||
//           lower.contains('discount') ||
//           lower.contains('savings') ||
//           lower.contains('refund')) {
//         continue;
//       }

//       final matches = amountRegex.allMatches(line);
//       for (final m in matches) {
//         final parsed = _tryParseReceiptAmount(m.group(0)!);
//         if (parsed != null && parsed > 0) {
//           candidates.add(parsed);
//         }
//       }
//     }

//     if (candidates.isNotEmpty) {
//       candidates.sort();
//       return candidates.last;
//     }

//     return null;
//   }

//   DateTime? _extractBestDateFromReceipt(String text) {
//     final normalized = _normalizeReceiptText(text);

//     final lines = normalized
//         .split('\n')
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();

//     final dateLabelRegex = RegExp(
//       r'(date|date/time|invoice date|transaction date)',
//       caseSensitive: false,
//     );

//     for (final line in lines) {
//       if (dateLabelRegex.hasMatch(line)) {
//         final parsed = _parseDate(line);
//         if (parsed != null) return parsed;
//       }
//     }

//     final patterns = [
//       RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}'),
//       RegExp(r'\d{2}\.\d{2}\.\d{2,4}'),
//       RegExp(r'\d{4}-\d{2}-\d{2}'),
//     ];

//     for (final line in lines) {
//       for (final pattern in patterns) {
//         final match = pattern.firstMatch(line);
//         if (match != null) {
//           final parsed = _parseDate(match.group(0)!);
//           if (parsed != null) return parsed;
//         }
//       }
//     }

//     return null;
//   }

//   DateTime? _extractDueDateFromReceipt(String text) {
//     final lines = text
//         .split('\n')
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();

//     const dueKeywords = [
//       'due date',
//       'payment due',
//       'due by',
//       'pay by',
//       'pay before',
//       'amount due',
//       'balance due',
//       'due on',
//     ];

//     for (final line in lines) {
//       final lower = line.toLowerCase();

//       for (final keyword in dueKeywords) {
//         if (lower.contains(keyword)) {
//           final parsed = _parseDate(line);
//           if (parsed != null) return parsed;
//         }
//       }
//     }

//     return null;
//   }

//   bool _detectIfPaid(String text) {
//     final lower = text.toLowerCase();

//     const unpaidKeywords = [
//       'amount due',
//       'balance due',
//       'payment due',
//       'due date',
//       'due by',
//       'pay by',
//       'pending',
//       'invoice',
//       'statement',
//     ];

//     const paidKeywords = [
//       'approved',
//       'paid',
//       'paid in full',
//       'payment received',
//       'completed',
//       'thank you for your purchase',
//       'visa',
//       'mastercard',
//       'debit',
//       'credit',
//       'cash',
//       'transaction id',
//       'auth code',
//       'authorization',
//       'change',
//       'tender',
//     ];

//     for (final keyword in unpaidKeywords) {
//       if (lower.contains(keyword)) return false;
//     }

//     for (final keyword in paidKeywords) {
//       if (lower.contains(keyword)) return true;
//     }

//     return false;
//   }

//   String? _detectPaymentMethodFromReceipt(String text) {
//     final lower = text.toLowerCase();

//     if (lower.contains('debit')) return 'Debit';
//     if (lower.contains('credit') ||
//         lower.contains('visa') ||
//         lower.contains('mastercard') ||
//         lower.contains('amex')) {
//       return 'Credit';
//     }
//     if (lower.contains('cash')) return 'Cash';
//     if (lower.contains('online') ||
//         lower.contains('paypal') ||
//         lower.contains('e-transfer') ||
//         lower.contains('etransfer')) {
//       return 'Online';
//     }

//     return null;
//   }

//   String? _extractBestLocationFromReceipt(String text) {
//     final lines = text
//         .split('\n')
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();

//     final addressCandidates = <String>[];

//     for (final line in lines) {
//       final lower = line.toLowerCase();

//       final looksLikeZipCity =
//           RegExp(r'\b\d{5}(?:-\d{4})?\b').hasMatch(line) ||
//           RegExp(r'\b\d{4,6}\b').hasMatch(line);

//       final looksLikeStreet =
//           lower.contains('street') ||
//           lower.contains('st.') ||
//           lower.contains('st ') ||
//           lower.contains('road') ||
//           lower.contains('rd') ||
//           lower.contains('ave') ||
//           lower.contains('avenue') ||
//           lower.contains('blvd') ||
//           lower.contains('drive') ||
//           lower.contains('dr ') ||
//           lower.contains('lane') ||
//           lower.contains('ln ') ||
//           lower.contains('finch avenue') ||
//           lower.contains('scarborough');

//       if (looksLikeStreet || looksLikeZipCity) {
//         addressCandidates.add(line);
//       }
//     }

//     if (addressCandidates.isEmpty) return null;
//     return addressCandidates.take(2).join(', ');
//   }

//   String _inferCategoryFromReceipt(String text) {
//     final lower = text.toLowerCase();

//     if (lower.contains('restaurant') ||
//         lower.contains('cafe') ||
//         lower.contains('latte') ||
//         lower.contains('macchiato') ||
//         lower.contains('pizza') ||
//         lower.contains('burger') ||
//         lower.contains('food') ||
//         lower.contains('bar') ||
//         lower.contains('hotel') ||
//         lower.contains('supermarket') ||
//         lower.contains('grocery') ||
//         lower.contains('eggplant') ||
//         lower.contains('onion') ||
//         lower.contains('mango') ||
//         lower.contains('pumpkin') ||
//         lower.contains('bittermelon') ||
//         lower.contains('drumstick') ||
//         lower.contains('longbean') ||
//         lower.contains('ash plant')) {
//       return 'Food';
//     }

//     if (lower.contains('uber') ||
//         lower.contains('taxi') ||
//         lower.contains('transit') ||
//         lower.contains('bus') ||
//         lower.contains('train') ||
//         lower.contains('metro') ||
//         lower.contains('gas') ||
//         lower.contains('fuel') ||
//         lower.contains('parking') ||
//         lower.contains('post') ||
//         lower.contains('parcel') ||
//         lower.contains('mail')) {
//       return 'Transport';
//     }

//     if (lower.contains('walmart') ||
//         lower.contains('store') ||
//         lower.contains('market') ||
//         lower.contains('mall') ||
//         lower.contains('purchase') ||
//         lower.contains('shopping')) {
//       return 'Shopping';
//     }

//     if (lower.contains('netflix') ||
//         lower.contains('spotify') ||
//         lower.contains('cinema') ||
//         lower.contains('movie') ||
//         lower.contains('game')) {
//       return 'Entertainment';
//     }

//     if (lower.contains('pharmacy') ||
//         lower.contains('clinic') ||
//         lower.contains('hospital') ||
//         lower.contains('medical') ||
//         lower.contains('drug')) {
//       return 'Health';
//     }

//     if (lower.contains('hydro') ||
//         lower.contains('electric') ||
//         lower.contains('internet') ||
//         lower.contains('phone bill') ||
//         lower.contains('insurance')) {
//       return 'Bills';
//     }

//     return 'Other';
//   }

//   Future<void> _extractExpenseFieldsFromRecognizedText(
//     RecognizedText recognizedText,
//   ) async {
//     final normalizedText = _normalizeReceiptText(
//       _buildReadableReceiptText(recognizedText),
//     );

//     if (normalizedText.isEmpty) return;

//     final bestTitle = _extractBestTitleFromRecognizedText(recognizedText);
//     if (bestTitle != null && bestTitle.trim().isNotEmpty) {
//       _titleCtrl.text = bestTitle;
//     }

//     final bestAmount = _extractBestAmountFromReceipt(normalizedText);
//     if (bestAmount != null) {
//       _amountCtrl.text = bestAmount.toStringAsFixed(2);
//     }

//     final bestDate = _extractBestDateFromReceipt(normalizedText);
//     if (bestDate != null) {
//       _date = bestDate;
//     }

//     final detectedDueDate = _extractDueDateFromReceipt(normalizedText);
//     if (detectedDueDate != null) {
//       _dueDate = detectedDueDate;
//       _isPaid = false;
//     } else {
//       _isPaid = _detectIfPaid(normalizedText);
//     }

//     final detectedPaymentMethod = _detectPaymentMethodFromReceipt(
//       normalizedText,
//     );
//     if (detectedPaymentMethod != null) {
//       _selectedPayment = detectedPaymentMethod;
//     }

//     _descCtrl.text = normalizedText;
//     _showDescription = normalizedText.isNotEmpty;

//     final bestLocation = _extractBestLocationFromReceipt(normalizedText);
//     if (bestLocation != null && bestLocation.trim().isNotEmpty) {
//       _locationCtrl.text = bestLocation;
//       // await _searchAndSelectLocation(bestLocation);
//     }

//     _selectedCategory = _inferCategoryFromReceipt(normalizedText);

//     if (mounted) {
//       setState(() {
//         _scannedRawText = normalizedText;
//       });
//     }
//   }

//   Future<void> _searchAndSelectLocation(String query) async {
//     final trimmed = query.trim();
//     if (trimmed.length < 3) return;

//     setState(() {
//       _isSearchingLocation = true;
//       _locationError = null;
//     });

//     try {
//       final results = await locationFromAddress(trimmed);

//       if (results.isEmpty) {
//         if (!mounted) return;
//         setState(() {
//           _locationPoint = null;
//           _locationError = 'No matching locations found';
//           _isSearchingLocation = false;
//         });
//         return;
//       }

//       final first = results.first;
//       final point = LatLng(first.latitude, first.longitude);

//       if (!mounted) return;
//       setState(() {
//         _locationPoint = point;
//         _locationError = null;
//         _isSearchingLocation = false;
//       });

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         try {
//           _mapController.move(point, 15);
//         } catch (_) {}
//       });
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         _locationPoint = null;
//         _locationError = 'Could not find location';
//         _isSearchingLocation = false;
//       });
//     }
//   }

//   Future<void> _pickDate() async {
//     HapticFeedback.selectionClick();

//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _date ?? now,
//       firstDate: DateTime(now.year - 5),
//       lastDate: DateTime(now.year + 5),
//     );

//     if (picked != null) {
//       HapticFeedback.lightImpact();
//       setState(() => _date = picked);
//     }
//   }

//   Future<void> _pickDueDate() async {
//     HapticFeedback.selectionClick();

//     final now = DateTime.now();
//     final initialDate = _dueDate ?? _date ?? now;
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(now.year - 5),
//       lastDate: DateTime(now.year + 10),
//     );

//     if (picked != null) {
//       HapticFeedback.lightImpact();
//       setState(() => _dueDate = picked);
//     }
//   }

//   String _getFrequencyLabel(RecurringFrequency freq) {
//     switch (freq) {
//       case RecurringFrequency.daily:
//         return 'every day';
//       case RecurringFrequency.biDaily:
//         return 'every other day';
//       case RecurringFrequency.monthly:
//         return 'monthly';
//       case RecurringFrequency.yearly:
//         return 'yearly';
//       default:
//         return 'as scheduled';
//     }
//   }

//   Future<void> _showRecurringFrequencyPicker() async {
//     final frequency = await showModalBottomSheet<RecurringFrequency>(
//       context: context,
//       builder: (context) {
//         return SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'How often should this repeat?',
//                   style: Theme.of(context).textTheme.headlineSmall,
//                 ),
//                 const SizedBox(height: 16),
//                 ListTile(
//                   title: const Text('Every Day'),
//                   onTap: () => Navigator.pop(context, RecurringFrequency.daily),
//                 ),
//                 ListTile(
//                   title: const Text('Every Other Day'),
//                   onTap: () =>
//                       Navigator.pop(context, RecurringFrequency.biDaily),
//                 ),
//                 ListTile(
//                   title: const Text('Once a Month'),
//                   onTap: () =>
//                       Navigator.pop(context, RecurringFrequency.monthly),
//                 ),
//                 ListTile(
//                   title: const Text('Once a Year'),
//                   onTap: () =>
//                       Navigator.pop(context, RecurringFrequency.yearly),
//                 ),
//                 const SizedBox(height: 8),
//               ],
//             ),
//           ),
//         );
//       },
//     );

//     if (frequency != null) {
//       setState(() {
//         _selectedFrequency = frequency;
//       });
//     }
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;

//     final amount = double.tryParse(_amountCtrl.text.trim());
//     if (amount == null || amount <= 0) {
//       HapticFeedback.heavyImpact();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Amount must be greater than 0')),
//       );
//       return;
//     }

//     final expense = Expense(
//       id: _isEditing ? widget.initialExpense!.id : null,
//       title: _titleCtrl.text.trim(),
//       amount: amount,
//       category: _selectedCategory,
//       date: _date,
//       dueDate: _dueDate,
//       description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
//       paymentMethod: _selectedPayment,
//       location: _locationCtrl.text.trim().isEmpty
//           ? null
//           : _locationCtrl.text.trim(),
//       isPaid: _isPaid,
//     );

//     if (_isEditing) {
//       await ExpenseDatabase.instance.updateExpense(expense);
//     } else {
//       await ExpenseDatabase.instance.insertExpense(expense);

//       if (_isRecurring && _selectedFrequency != null) {
//         final recurringExpense = RecurringExpense(
//           title: _titleCtrl.text.trim(),
//           amount: amount,
//           category: _selectedCategory,
//           paymentMethod: _selectedPayment,
//           description: _descCtrl.text.trim().isEmpty
//               ? null
//               : _descCtrl.text.trim(),
//           location: _locationCtrl.text.trim().isEmpty
//               ? null
//               : _locationCtrl.text.trim(),
//           startDate: _date ?? DateTime.now(),
//           frequency: _selectedFrequency!,
//           nextDueDate: _date ?? DateTime.now(),
//         );

//         await ExpenseDatabase.instance.insertRecurringExpense(recurringExpense);
//       }
//     }

//     HapticFeedback.mediumImpact();
//     if (!mounted) return;
//     Navigator.pop(context, true);
//   }

//   Widget _buildMiniFab({
//     required IconData icon,
//     required String heroTag,
//     required VoidCallback onPressed,
//   }) {
//     return ScaleTransition(
//       scale: _fabAnimation,
//       child: FloatingActionButton.small(
//         heroTag: heroTag,
//         onPressed: onPressed,
//         child: Icon(icon),
//       ),
//     );
//   }

//   Widget _buildRecurringSection(ColorScheme scheme) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: scheme.primary.withValues(alpha: 0.3),
//           width: 1.5,
//         ),
//         borderRadius: BorderRadius.circular(14),
//         color: _isRecurring
//             ? scheme.primary.withValues(alpha: 0.08)
//             : Colors.transparent,
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Recurring Payment',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w800,
//                     color: scheme.onSurface,
//                   ),
//                 ),
//                 if (_isRecurring && _selectedFrequency != null) ...[
//                   const SizedBox(height: 4),
//                   Text(
//                     'Repeats ${_getFrequencyLabel(_selectedFrequency!)}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: scheme.onSurfaceVariant,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           SizedBox(
//             width: 110,
//             child: !_isRecurring
//                 ? OutlinedButton(
//                     onPressed: () async {
//                       HapticFeedback.selectionClick();
//                       setState(() => _isRecurring = true);
//                       await _showRecurringFrequencyPicker();
//                     },
//                     child: const Text('Enable'),
//                   )
//                 : OutlinedButton(
//                     onPressed: () {
//                       HapticFeedback.selectionClick();
//                       setState(() {
//                         _isRecurring = false;
//                         _selectedFrequency = null;
//                       });
//                     },
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: scheme.error,
//                       side: BorderSide(color: scheme.error),
//                     ),
//                     child: const Text('Disable'),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           _isEditing
//               ? 'Edit Expense'
//               : (widget.duplicateMode ? 'Duplicate Expense' : 'Add Expense'),
//         ),
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       TextFormField(
//                         controller: _titleCtrl,
//                         textInputAction: TextInputAction.next,
//                         decoration: const InputDecoration(
//                           labelText: 'Title',
//                           prefixIcon: Icon(Icons.title),
//                         ),
//                         validator: (v) {
//                           if (v == null || v.trim().isEmpty) {
//                             return 'Title is required';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _amountCtrl,
//                         keyboardType: const TextInputType.numberWithOptions(
//                           decimal: true,
//                         ),
//                         textInputAction: TextInputAction.next,
//                         decoration: const InputDecoration(
//                           labelText: 'Amount',
//                           hintText: 'e.g., 12.50',
//                           prefixIcon: Icon(Icons.attach_money),
//                         ),
//                         validator: (v) {
//                           if (v == null || v.trim().isEmpty) {
//                             return 'Amount is required';
//                           }
//                           return null;
//                         },
//                       ),
//                       if (_isScanningReceipt) ...[
//                         const SizedBox(height: 12),
//                         const Row(
//                           children: [
//                             SizedBox(
//                               width: 18,
//                               height: 18,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             ),
//                             SizedBox(width: 10),
//                             Text(
//                               'Scanning receipt...',
//                               style: TextStyle(fontWeight: FontWeight.w700),
//                             ),
//                           ],
//                         ),
//                       ],
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _locationCtrl,
//                         textInputAction: TextInputAction.search,
//                         decoration: InputDecoration(
//                           labelText: 'Location (optional)',
//                           prefixIcon: const Icon(Icons.location_on_outlined),
//                           suffixIcon: _isSearchingLocation
//                               ? const Padding(
//                                   padding: EdgeInsets.all(12),
//                                   child: SizedBox(
//                                     width: 18,
//                                     height: 18,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                     ),
//                                   ),
//                                 )
//                               : (_locationPoint != null
//                                     ? const Icon(Icons.check_circle_outline)
//                                     : null),
//                         ),
//                         onChanged: (value) {
//                           if (value.trim().isEmpty) {
//                             setState(() {
//                               _locationPoint = null;
//                               _locationError = null;
//                             });
//                           }
//                         },
//                         onFieldSubmitted: (value) async {
//                           await _searchAndSelectLocation(value);
//                         },
//                       ),
//                       const SizedBox(height: 10),
//                       SizedBox(
//                         width: double.infinity,
//                         child: OutlinedButton.icon(
//                           onPressed: () async {
//                             await _searchAndSelectLocation(_locationCtrl.text);
//                           },
//                           icon: const Icon(Icons.search),
//                           label: const Text('Search Location'),
//                         ),
//                       ),
//                       if (_locationError != null) ...[
//                         const SizedBox(height: 8),
//                         Text(
//                           _locationError!,
//                           style: TextStyle(
//                             color: scheme.error,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                       if (_locationPoint != null) ...[
//                         const SizedBox(height: 12),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: SizedBox(
//                             height: 220,
//                             width: double.infinity,
//                             child: FlutterMap(
//                               mapController: _mapController,
//                               options: MapOptions(
//                                 initialCenter: _locationPoint!,
//                                 initialZoom: 15,
//                               ),
//                               children: [
//                                 TileLayer(
//                                   urlTemplate:
//                                       'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
//                                   userAgentPackageName: 'com.example.app',
//                                 ),
//                                 MarkerLayer(
//                                   markers: [
//                                     Marker(
//                                       point: _locationPoint!,
//                                       width: 44,
//                                       height: 44,
//                                       child: const Icon(
//                                         Icons.location_pin,
//                                         size: 44,
//                                         color: Colors.red,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                       if (_scannedRawText != null &&
//                           _scannedRawText!.trim().isNotEmpty) ...[
//                         const SizedBox(height: 12),
//                         Text(
//                           'Scanned Text Preview',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w800,
//                             color: scheme.onSurface,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: scheme.surfaceContainerHighest.withValues(
//                               alpha: 0.45,
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             _scannedRawText!,
//                             maxLines: 12,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               color: scheme.onSurfaceVariant,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                       const SizedBox(height: 16),
//                       Text(
//                         'Category',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w900,
//                           color: scheme.onSurface,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: _categories.map((c) {
//                           final selected = _selectedCategory == c;
//                           return ChoiceChip(
//                             label: Text(c),
//                             selected: selected,
//                             onSelected: (_) {
//                               HapticFeedback.selectionClick();
//                               setState(() => _selectedCategory = c);
//                             },
//                           );
//                         }).toList(),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Payment',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w900,
//                           color: scheme.onSurface,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: _paymentMethods.map((p) {
//                           final selected = _selectedPayment == p;
//                           return ChoiceChip(
//                             label: Text(p),
//                             selected: selected,
//                             onSelected: (_) {
//                               HapticFeedback.selectionClick();
//                               setState(() => _selectedPayment = p);
//                             },
//                           );
//                         }).toList(),
//                       ),
//                       const SizedBox(height: 16),
//                       _buildRecurringSection(scheme),
//                       const SizedBox(height: 16),
//                       SizedBox(
//                         width: double.infinity,
//                         child: OutlinedButton.icon(
//                           onPressed: _pickDate,
//                           icon: const Icon(Icons.calendar_month_outlined),
//                           label: Text(
//                             _date == null
//                                 ? 'Pick date'
//                                 : 'Date: ${_date!.toLocal().toString().split(' ').first}',
//                             style: const TextStyle(fontWeight: FontWeight.w800),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       SizedBox(
//                         width: double.infinity,
//                         child: OutlinedButton.icon(
//                           onPressed: _pickDueDate,
//                           icon: const Icon(Icons.event_available_outlined),
//                           label: Text(
//                             _dueDate == null
//                                 ? 'Pick due date (optional)'
//                                 : 'Due Date: ${_dueDate!.toLocal().toString().split(' ').first}',
//                             style: const TextStyle(fontWeight: FontWeight.w800),
//                           ),
//                         ),
//                       ),
//                       if (_dueDate != null) ...[
//                         const SizedBox(height: 8),
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton.icon(
//                             onPressed: () {
//                               HapticFeedback.selectionClick();
//                               setState(() => _dueDate = null);
//                             },
//                             icon: const Icon(Icons.close),
//                             label: const Text('Clear due date'),
//                           ),
//                         ),
//                       ],
//                       const SizedBox(height: 10),
//                       CheckboxListTile(
//                         contentPadding: EdgeInsets.zero,
//                         value: _isPaid,
//                         onChanged: (value) {
//                           HapticFeedback.selectionClick();
//                           setState(() => _isPaid = value ?? false);
//                         },
//                         title: const Text(
//                           'Mark as already paid',
//                           style: TextStyle(fontWeight: FontWeight.w800),
//                         ),
//                         subtitle: const Text(
//                           'Turn this on if you already settled this expense.',
//                         ),
//                         controlAffinity: ListTileControlAffinity.leading,
//                       ),
//                       const SizedBox(height: 10),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               'Add description',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w800,
//                                 color: scheme.onSurface,
//                               ),
//                             ),
//                           ),
//                           Switch(
//                             value: _showDescription,
//                             onChanged: (v) {
//                               HapticFeedback.selectionClick();
//                               setState(() => _showDescription = v);
//                             },
//                           ),
//                         ],
//                       ),
//                       AnimatedSize(
//                         duration: const Duration(milliseconds: 200),
//                         curve: Curves.easeOut,
//                         child: _showDescription
//                             ? Column(
//                                 children: [
//                                   const SizedBox(height: 6),
//                                   TextFormField(
//                                     controller: _descCtrl,
//                                     maxLines: 3,
//                                     decoration: const InputDecoration(
//                                       labelText: 'Description (optional)',
//                                       prefixIcon: Icon(Icons.notes_outlined),
//                                     ),
//                                   ),
//                                 ],
//                               )
//                             : const SizedBox.shrink(),
//                       ),
//                       const SizedBox(height: 18),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           onPressed: _save,
//                           icon: const Icon(Icons.save),
//                           label: const Text('Save Expense'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: _isEditing
//           ? null
//           : Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 if (_isFabOpen) ...[
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         margin: const EdgeInsets.only(right: 8),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: scheme.surface,
//                           borderRadius: BorderRadius.circular(10),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.08),
//                               blurRadius: 8,
//                             ),
//                           ],
//                         ),
//                         child: const Text(
//                           'Import File',
//                           style: TextStyle(fontWeight: FontWeight.w700),
//                         ),
//                       ),
//                       _buildMiniFab(
//                         icon: Icons.description_outlined,
//                         heroTag: 'file_fab',
//                         onPressed: _onFileTap,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         margin: const EdgeInsets.only(right: 8),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: scheme.surface,
//                           borderRadius: BorderRadius.circular(10),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.08),
//                               blurRadius: 8,
//                             ),
//                           ],
//                         ),
//                         child: const Text(
//                           'Scan Receipt',
//                           style: TextStyle(fontWeight: FontWeight.w700),
//                         ),
//                       ),
//                       _buildMiniFab(
//                         icon: Icons.camera_alt_outlined,
//                         heroTag: 'camera_fab',
//                         onPressed: _onCameraTap,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                 ],
//                 FloatingActionButton(
//                   heroTag: 'main_expandable_fab',
//                   onPressed: _toggleFab,
//                   child: AnimatedRotation(
//                     turns: _isFabOpen ? 0.125 : 0,
//                     duration: const Duration(milliseconds: 220),
//                     child: Icon(_isFabOpen ? Icons.close : Icons.add),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }

// import 'dart:async';
// import 'dart:io';

// import 'package:csv/csv.dart';
// import 'package:excel/excel.dart' hide Border;
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:latlong2/latlong.dart';

// import 'database/expense_database.dart';
// import 'models/expense.dart';

// class AddExpensePage extends StatefulWidget {
//   final Expense? initialExpense;
//   final bool duplicateMode;

//   const AddExpensePage({
//     super.key,
//     this.initialExpense,
//     this.duplicateMode = false,
//   });

//   @override
//   State<AddExpensePage> createState() => _AddExpensePageState();
// }

// class _AddExpensePageState extends State<AddExpensePage>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();

//   final _titleCtrl = TextEditingController();
//   final _amountCtrl = TextEditingController();
//   final _descCtrl = TextEditingController();
//   final _locationCtrl = TextEditingController();

//   final ImagePicker _imagePicker = ImagePicker();

//   DateTime? _date = DateTime.now();
//   DateTime? _dueDate;
//   bool _isPaid = false;
//   bool _isRecurring = false;
//   RecurringFrequency? _selectedFrequency;

//   final List<String> _categories = const [
//     'Food',
//     'Transport',
//     'Bills',
//     'Shopping',
//     'Entertainment',
//     'Health',
//     'Other',
//   ];

//   final List<String> _paymentMethods = const [
//     'Cash',
//     'Debit',
//     'Credit',
//     'Online',
//   ];

//   String _selectedCategory = 'Food';
//   String _selectedPayment = 'Debit';
//   bool _showDescription = false;

//   bool _isFabOpen = false;
//   late AnimationController _fabController;
//   late Animation<double> _fabAnimation;

//   final MapController _mapController = MapController();
//   LatLng? _locationPoint;
//   bool _isSearchingLocation = false;
//   String? _locationError;
//   Timer? _locationDebounce;

//   bool _isScanningReceipt = false;
//   String? _scannedRawText;

//   bool get _isEditing =>
//       widget.initialExpense != null && widget.duplicateMode == false;

//   @override
//   void initState() {
//     super.initState();

//     _fabController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 220),
//     );
//     _fabAnimation = CurvedAnimation(
//       parent: _fabController,
//       curve: Curves.easeOut,
//     );

//     _recoverLostCameraImage();

//     final initial = widget.initialExpense;
//     if (initial != null) {
//       _titleCtrl.text = initial.title;
//       _amountCtrl.text = initial.amount.toStringAsFixed(2);
//       _descCtrl.text = initial.description ?? '';
//       _locationCtrl.text = initial.location ?? '';
//       _date = initial.date ?? DateTime.now();
//       _dueDate = initial.dueDate;
//       _selectedCategory = _categories.contains(initial.category)
//           ? initial.category
//           : 'Other';
//       _selectedPayment = _paymentMethods.contains(initial.paymentMethod)
//           ? initial.paymentMethod
//           : 'Cash';
//       _showDescription = _descCtrl.text.trim().isNotEmpty;
//       _isPaid = widget.duplicateMode ? false : initial.isPaid;

//       if ((initial.location ?? '').trim().isNotEmpty) {
//         WidgetsBinding.instance.addPostFrameCallback((_) async {
//           await _searchAndSelectLocation(initial.location!);
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _locationDebounce?.cancel();
//     _titleCtrl.dispose();
//     _amountCtrl.dispose();
//     _descCtrl.dispose();
//     _locationCtrl.dispose();
//     _fabController.dispose();
//     super.dispose();
//   }

//   void _toggleFab() {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _isFabOpen = !_isFabOpen;
//     });

//     if (_isFabOpen) {
//       _fabController.forward();
//     } else {
//       _fabController.reverse();
//     }
//   }

//   void _onLocationChanged(String value) {
//     _locationDebounce?.cancel();

//     final trimmed = value.trim();

//     if (trimmed.isEmpty) {
//       if (!mounted) return;
//       setState(() {
//         _locationPoint = null;
//         _locationError = null;
//         _isSearchingLocation = false;
//       });
//       return;
//     }

//     if (trimmed.length < 3) {
//       if (!mounted) return;
//       setState(() {
//         _locationError = null;
//       });
//       return;
//     }

//     _locationDebounce = Timer(const Duration(milliseconds: 650), () async {
//       if (!mounted) return;
//       await _searchAndSelectLocation(trimmed);
//     });
//   }

//   Future<void> _recoverLostCameraImage() async {
//     try {
//       final LostDataResponse response = await _imagePicker.retrieveLostData();

//       if (response.isEmpty) return;

//       if (response.files != null && response.files!.isNotEmpty) {
//         await _processPickedReceiptFile(response.files!.first);
//         return;
//       }

//       if (response.file != null) {
//         await _processPickedReceiptFile(response.file!);
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to recover camera image: $e')),
//       );
//     }
//   }

//   Future<void> _processPickedReceiptFile(XFile pickedFile) async {
//     TextRecognizer? textRecognizer;

//     try {
//       if (!mounted) return;

//       setState(() {
//         _isScanningReceipt = true;
//         _scannedRawText = null;
//       });

//       final inputImage = InputImage.fromFilePath(pickedFile.path);
//       textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

//       final recognizedText = await textRecognizer.processImage(inputImage);
//       final rebuiltText = _buildReadableReceiptText(recognizedText);

//       if (!mounted) return;
//       setState(() {
//         _scannedRawText = rebuiltText;
//       });

//       await _extractExpenseFieldsFromRecognizedText(recognizedText);

//       if (!mounted) return;
//       HapticFeedback.mediumImpact();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             rebuiltText.isEmpty
//                 ? 'Scan finished, but no text was detected'
//                 : 'Receipt scanned successfully',
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       HapticFeedback.heavyImpact();
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
//     } finally {
//       try {
//         await textRecognizer?.close();
//       } catch (_) {}

//       if (mounted) {
//         setState(() {
//           _isScanningReceipt = false;
//         });
//       }
//     }
//   }

//   Future<void> _onCameraTap() async {
//     if (_isScanningReceipt) return;

//     HapticFeedback.lightImpact();

//     if (mounted) {
//       setState(() {
//         _isFabOpen = false;
//       });
//     }
//     _fabController.reverse();

//     try {
//       final XFile? pickedFile = await _imagePicker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 70,
//         maxWidth: 900,
//         maxHeight: 900,
//         preferredCameraDevice: CameraDevice.rear,
//       );

//       if (pickedFile == null) return;
//       await Future.delayed(const Duration(milliseconds: 300));
//       await _processPickedReceiptFile(pickedFile);
//     } catch (e) {
//       if (!mounted) return;
//       HapticFeedback.heavyImpact();
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
//     }
//   }

//   Future<void> _onFileTap() async {
//     HapticFeedback.lightImpact();

//     setState(() {
//       _isFabOpen = false;
//     });
//     _fabController.reverse();

//     await _importExpenseFile();
//   }

//   Future<void> _importExpenseFile() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['csv', 'xlsx', 'xls'],
//         allowMultiple: false,
//       );

//       if (result == null || result.files.isEmpty) return;

//       final picked = result.files.single;
//       final path = picked.path;
//       if (path == null) {
//         throw Exception('Unable to read selected file path.');
//       }

//       final extension = (picked.extension ?? '').toLowerCase();
//       final file = File(path);

//       List<Map<String, dynamic>> rows = [];

//       if (extension == 'csv') {
//         final input = await file.readAsString();
//         final csvTable = const CsvToListConverter().convert(input);

//         if (csvTable.isEmpty) {
//           throw Exception('CSV file is empty.');
//         }

//         final headers = csvTable.first
//             .map((e) => e.toString().trim().toLowerCase())
//             .toList();

//         for (int i = 1; i < csvTable.length; i++) {
//           final row = csvTable[i];
//           if (_isRowCompletelyEmpty(row)) continue;

//           final data = <String, dynamic>{};
//           for (int j = 0; j < headers.length && j < row.length; j++) {
//             data[headers[j]] = row[j];
//           }

//           if (!_looksLikeExpenseRow(data)) continue;
//           rows.add(data);
//         }
//       } else if (extension == 'xlsx' || extension == 'xls') {
//         final bytes = await file.readAsBytes();
//         final excel = Excel.decodeBytes(bytes);

//         if (excel.tables.isEmpty) {
//           throw Exception('Excel file has no sheets.');
//         }

//         final sheet = excel.tables.values.first;
//         if (sheet.rows.isEmpty) {
//           throw Exception('Excel sheet is empty.');
//         }

//         final headers = sheet.rows.first
//             .map((cell) => cell?.value.toString().trim().toLowerCase() ?? '')
//             .toList();

//         for (int i = 1; i < sheet.rows.length; i++) {
//           final row = sheet.rows[i];
//           if (_isExcelRowEmpty(row)) continue;

//           final data = <String, dynamic>{};
//           for (int j = 0; j < headers.length && j < row.length; j++) {
//             data[headers[j]] = row[j]?.value;
//           }

//           if (!_looksLikeExpenseRow(data)) continue;
//           rows.add(data);
//         }
//       } else {
//         throw Exception('Unsupported file type.');
//       }

//       final toImport = <Expense>[];

//       for (final row in rows) {
//         final amount = _parseAmount(
//           _readAny(row, const [
//             'amount',
//             'cost',
//             'price',
//             'expense',
//             r'$',
//             'total',
//           ]),
//         );

//         if (amount == null || amount <= 0) continue;

//         final parsedDate = _parseDate(
//           _readAny(row, const ['date', 'expense date', 'day']),
//         );

//         final description = _stringValue(
//           _readAny(row, const ['description', 'details', 'note']),
//         );

//         final title =
//             _stringValue(_readAny(row, const ['title', 'name', 'item'])) ??
//             description ??
//             'Imported Expense';

//         final categoryText = _stringValue(
//           _readAny(row, const ['category', 'type']),
//         );

//         final paymentText = _stringValue(
//           _readAny(row, const ['payment', 'payment method', 'method']),
//         );

//         final locationText = _stringValue(
//           _readAny(row, const ['location', 'place', 'store']),
//         );

//         final combinedText = [
//           title,
//           if (description != null) description,
//           if (locationText != null) locationText,
//           if (categoryText != null) categoryText,
//         ].join('\n');

//         toImport.add(
//           Expense(
//             title: title,
//             amount: amount,
//             category:
//                 _normalizeCategory(categoryText) ??
//                 _inferCategoryFromReceipt(combinedText),
//             date: parsedDate ?? DateTime.now(),
//             dueDate: null,
//             description: description,
//             paymentMethod: _normalizePaymentMethod(paymentText) ?? 'Cash',
//             location: locationText,
//             isPaid: false,
//           ),
//         );
//       }

//       await ExpenseDatabase.instance.insertExpenses(toImport);
//       final importedCount = toImport.length;

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             importedCount > 0
//                 ? 'Imported $importedCount expense(s)'
//                 : 'No valid expense rows found in file',
//           ),
//         ),
//       );

//       if (importedCount > 0) {
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
//     }
//   }

//   bool _isRowCompletelyEmpty(List<dynamic> row) {
//     for (final cell in row) {
//       if (cell != null && cell.toString().trim().isNotEmpty) {
//         return false;
//       }
//     }
//     return true;
//   }

//   bool _isExcelRowEmpty(List<Data?> row) {
//     for (final cell in row) {
//       if (cell?.value != null && cell!.value.toString().trim().isNotEmpty) {
//         return false;
//       }
//     }
//     return true;
//   }

//   bool _looksLikeExpenseRow(Map<String, dynamic> row) {
//     final joined = row.values
//         .map((e) => e?.toString().toLowerCase() ?? '')
//         .join(' ');

//     if (joined.contains('total expenses') ||
//         joined.contains('grand total') ||
//         joined.contains('subtotal')) {
//       return false;
//     }
//     return true;
//   }

//   dynamic _readAny(Map<String, dynamic> row, List<String> possibleKeys) {
//     for (final key in possibleKeys) {
//       for (final existingKey in row.keys) {
//         if (existingKey.trim().toLowerCase() == key.trim().toLowerCase()) {
//           return row[existingKey];
//         }
//       }
//     }
//     return null;
//   }

//   String? _stringValue(dynamic value) {
//     if (value == null) return null;
//     final text = value.toString().trim();
//     if (text.isEmpty) return null;
//     return text;
//   }

//   double? _parseAmount(dynamic value) {
//     if (value == null) return null;

//     final raw = value.toString().trim();
//     if (raw.isEmpty) return null;

//     final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
//     if (cleaned.isEmpty) return null;

//     return double.tryParse(cleaned);
//   }

//   DateTime? _parseDate(dynamic value) {
//     if (value == null) return null;
//     if (value is DateTime) return value;

//     var raw = value.toString().trim();
//     if (raw.isEmpty) return null;

//     raw = raw.replaceAll('O', '0').replaceAll('o', '0');

//     final direct = DateTime.tryParse(raw);
//     if (direct != null) return direct;

//     final match = RegExp(
//       r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{2}\.\d{2}\.\d{2,4}|\d{4}-\d{2}-\d{2})',
//     ).firstMatch(raw);

//     final dateOnly = match != null ? match.group(0)! : raw;

//     final slashParts = dateOnly.split('/');
//     if (slashParts.length == 3) {
//       final month = int.tryParse(slashParts[0]);
//       final day = int.tryParse(slashParts[1]);
//       var year = int.tryParse(slashParts[2]);

//       if (month != null && day != null && year != null) {
//         if (year < 100) {
//           year += (year >= 70) ? 1900 : 2000;
//         }
//         if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
//           return DateTime(year, month, day);
//         }
//       }
//     }

//     final dashParts = dateOnly.split('-');
//     if (dashParts.length == 3) {
//       final y1 = int.tryParse(dashParts[0]);
//       final m1 = int.tryParse(dashParts[1]);
//       final d1 = int.tryParse(dashParts[2]);

//       if (y1 != null && m1 != null && d1 != null) {
//         if (y1 > 999 && m1 >= 1 && m1 <= 12 && d1 >= 1 && d1 <= 31) {
//           return DateTime(y1, m1, d1);
//         }
//       }

//       final day = int.tryParse(dashParts[0]);
//       final month = int.tryParse(dashParts[1]);
//       var year = int.tryParse(dashParts[2]);

//       if (day != null && month != null && year != null) {
//         if (year < 100) {
//           year += (year >= 70) ? 1900 : 2000;
//         }
//         if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
//           return DateTime(year, month, day);
//         }
//       }
//     }

//     final dotParts = dateOnly.split('.');
//     if (dotParts.length == 3) {
//       final day = int.tryParse(dotParts[0]);
//       final month = int.tryParse(dotParts[1]);
//       var year = int.tryParse(dotParts[2]);

//       if (day != null && month != null && year != null) {
//         if (year < 100) {
//           year += (year >= 70) ? 1900 : 2000;
//         }
//         if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
//           return DateTime(year, month, day);
//         }
//       }
//     }

//     return null;
//   }

//   String? _normalizeCategory(dynamic value) {
//     final text = _stringValue(value);
//     if (text == null) return null;

//     for (final category in _categories) {
//       if (category.toLowerCase() == text.toLowerCase()) {
//         return category;
//       }
//     }

//     return text;
//   }

//   String? _normalizePaymentMethod(dynamic value) {
//     final text = _stringValue(value);
//     if (text == null) return null;

//     for (final method in _paymentMethods) {
//       if (method.toLowerCase() == text.toLowerCase()) {
//         return method;
//       }
//     }

//     final lower = text.toLowerCase();
//     if (lower.contains('debit')) return 'Debit';
//     if (lower.contains('credit')) return 'Credit';
//     if (lower.contains('cash')) return 'Cash';
//     if (lower.contains('online')) return 'Online';

//     return text;
//   }

//   String _normalizeReceiptText(String text) {
//     return text
//         .replaceAll('O', '0')
//         .replaceAll('o', '0')
//         .replaceAll('SFr', 'CHF');
//   }

//   List<String> _extractOrderedLinesFromRecognizedText(RecognizedText text) {
//     final lines = <Map<String, dynamic>>[];

//     for (final block in text.blocks) {
//       for (final line in block.lines) {
//         final raw = line.text.trim();
//         if (raw.isEmpty) continue;

//         lines.add({
//           'text': raw,
//           'top': line.boundingBox.top.toDouble(),
//           'left': line.boundingBox.left.toDouble(),
//         });
//       }
//     }

//     if (lines.isEmpty) return [];

//     lines.sort((a, b) {
//       final double topA = a['top'] as double;
//       final double topB = b['top'] as double;
//       final double leftA = a['left'] as double;
//       final double leftB = b['left'] as double;

//       final double topDiff = (topA - topB).abs();
//       if (topDiff <= 14) {
//         return leftA.compareTo(leftB);
//       }
//       return topA.compareTo(topB);
//     });

//     return lines.map((e) => e['text'] as String).toList();
//   }

//   String _buildReadableReceiptText(RecognizedText text) {
//     final orderedLines = _extractOrderedLinesFromRecognizedText(text);
//     return orderedLines.join('\n').trim();
//   }

//   bool _looksLikeHeaderStopLine(String line) {
//     final lower = line.toLowerCase().trim();

//     return lower.contains('date/time') ||
//         lower.startsWith('date') ||
//         lower.contains('receipt #') ||
//         lower.contains('receipt#:') ||
//         lower.contains('station #') ||
//         lower.contains('cashier') ||
//         lower == 'sale' ||
//         lower == 'qty' ||
//         lower.contains('qty ') ||
//         lower == 'product' ||
//         lower == 'price' ||
//         lower == 'sum' ||
//         (lower.contains('qty') &&
//             lower.contains('product') &&
//             (lower.contains('price') || lower.contains('sum')));
//   }

//   bool _isBadMerchantLine(String line) {
//     final lower = line.toLowerCase().trim();

//     if (lower.isEmpty) return true;

//     if (lower.contains('receipt') ||
//         lower.contains('invoice') ||
//         lower == 'sale' ||
//         lower == 'qty' ||
//         lower == 'product' ||
//         lower == 'price' ||
//         lower == 'sum' ||
//         lower.contains('date') ||
//         lower.contains('time') ||
//         lower.contains('station') ||
//         lower.contains('cashier') ||
//         lower.contains('hst') ||
//         lower.contains('gst') ||
//         lower.contains('tax') ||
//         lower.contains('tel') ||
//         lower.contains('fax') ||
//         lower.contains('www') ||
//         lower.contains('.com') ||
//         lower.contains('card transaction record')) {
//       return true;
//     }

//     if (RegExp(r'^\d[\d/\-:. ]+$').hasMatch(lower)) return true;
//     if (RegExp(r'^\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}$').hasMatch(lower)) {
//       return true;
//     }
//     if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(lower)) {
//       return true;
//     }

//     return false;
//   }

//   String _cleanMerchantTitle(String value) {
//     var text = value.trim();
//     if (text.isEmpty) return text;

//     text = text.replaceAll(RegExp(r'\s+'), ' ');
//     text = text.replaceAll(
//       RegExp(r'(?<=\D)0(?=\D)|(?<=\b)0(?=\D)|(?<=\D)0(?=\b)'),
//       'O',
//     );

//     if (text == text.toUpperCase()) {
//       return text
//           .split(RegExp(r'\s+'))
//           .where((w) => w.isNotEmpty)
//           .map((w) {
//             if (w.length == 1) return w.toUpperCase();
//             return w[0].toUpperCase() + w.substring(1).toLowerCase();
//           })
//           .join(' ');
//     }

//     return text;
//   }

//   String? _extractBestTitleFromRecognizedText(RecognizedText text) {
//     final lines = _extractOrderedLinesFromRecognizedText(text);
//     if (lines.isEmpty) return null;

//     final topLines = lines.take(10).toList();

//     final headerLines = <String>[];
//     for (final line in topLines) {
//       if (_looksLikeHeaderStopLine(line)) break;
//       headerLines.add(line);
//     }

//     bool looksLikeAddress(String line) {
//       final lower = line.toLowerCase();
//       return RegExp(r'\d').hasMatch(line) &&
//           (lower.contains('avenue') ||
//               lower.contains('street') ||
//               lower.contains('road') ||
//               lower.contains('drive') ||
//               lower.contains('blvd') ||
//               lower.contains('ont') ||
//               lower.contains('scarborough'));
//     }

//     int scoreLine(String line, int index) {
//       int score = 0;
//       final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
//       final digits = RegExp(r'\d').allMatches(line).length;

//       if (index == 0) score += 40;
//       if (index == 1) score += 25;
//       if (index == 2) score += 12;

//       if (letters >= 5) score += 18;
//       if (digits == 0) score += 12;
//       if (line.length >= 4 && line.length <= 30) score += 14;
//       if (line == line.toUpperCase()) score += 6;
//       if (looksLikeAddress(line)) score -= 35;
//       if (_isBadMerchantLine(line)) score -= 100;

//       return score;
//     }

//     String? bestLine;
//     int bestScore = -9999;

//     for (int i = 0; i < headerLines.length; i++) {
//       final line = headerLines[i];

//       final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
//       final digits = RegExp(r'\d').allMatches(line).length;

//       if (letters < 3) continue;
//       if (digits > letters) continue;
//       if (_isBadMerchantLine(line)) continue;

//       final score = scoreLine(line, i);
//       if (score > bestScore) {
//         bestScore = score;
//         bestLine = line;
//       }
//     }

//     if (bestLine != null && bestLine.trim().isNotEmpty) {
//       return _cleanMerchantTitle(
//         bestLine.length > 40 ? bestLine.substring(0, 40) : bestLine,
//       );
//     }

//     for (final line in topLines) {
//       if (!_isBadMerchantLine(line)) {
//         return _cleanMerchantTitle(
//           line.length > 40 ? line.substring(0, 40) : line,
//         );
//       }
//     }

//     return _cleanMerchantTitle(
//       lines.first.length > 40 ? lines.first.substring(0, 40) : lines.first,
//     );
//   }

//   double? _tryParseReceiptAmount(String raw) {
//     var cleaned = raw.trim();
//     cleaned = cleaned.replaceAll(RegExp(r'[^0-9,.\-]'), '');

//     if (cleaned.contains(',') && cleaned.contains('.')) {
//       cleaned = cleaned.replaceAll(',', '');
//     } else if (cleaned.contains(',') && !cleaned.contains('.')) {
//       cleaned = cleaned.replaceAll(',', '.');
//     }

//     return double.tryParse(cleaned);
//   }

//   double? _extractBestAmountFromReceipt(String text) {
//     final normalized = _normalizeReceiptText(text);

//     final lines = normalized
//         .split('\n')
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();

//     final amountRegex = RegExp(r'(?<!\d)(\d{1,4}[.,]\d{2})(?!\d)');

//     double? parseLastAmount(String line) {
//       final matches = amountRegex.allMatches(line).toList();
//       if (matches.isEmpty) return null;
//       return _tryParseReceiptAmount(matches.last.group(0)!);
//     }

//     bool containsAny(String line, List<String> keywords) {
//       final lower = line.toLowerCase();
//       return keywords.any((k) => lower.contains(k));
//     }

//     bool containsNone(String line, List<String> keywords) {
//       final lower = line.toLowerCase();
//       return keywords.every((k) => !lower.contains(k));
//     }

//     const priority1 = [
//       'grand total',
//       'amount due',
//       'balance due',
//       'total due',
//       'net total',
//     ];

//     for (final line in lines.reversed) {
//       if (containsAny(line, priority1)) {
//         final parsed = parseLastAmount(line);
//         if (parsed != null && parsed > 0) return parsed;
//       }
//     }

//     const excludedTotalWords = [
//       'tax',
//       'total tax',
//       'subtotal',
//       'sub total',
//       'hst',
//       'gst',
//       'vat',
//       'tip',
//       'change',
//       'discount',
//       'savings',
//       'refund',
//     ];

//     for (final line in lines.reversed) {
//       final lower = line.toLowerCase();
//       if (lower.contains('total') && containsNone(line, excludedTotalWords)) {
//         final parsed = parseLastAmount(line);
//         if (parsed != null && parsed > 0) return parsed;
//       }
//     }

//     for (final line in lines.reversed.take(12)) {
//       final lower = line.toLowerCase();
//       if ((lower.contains('approved') ||
//               lower.contains('paid') ||
//               lower.contains('debit') ||
//               lower.contains('credit') ||
//               lower.contains('visa') ||
//               lower.contains('mastercard')) &&
//           !lower.contains('card number')) {
//         final parsed = parseLastAmount(line);
//         if (parsed != null && parsed > 0) return parsed;
//       }
//     }

//     final candidates = <double>[];

//     for (final line in lines) {
//       final lower = line.toLowerCase();

//       if (lower.contains('tax') ||
//           lower.contains('hst') ||
//           lower.contains('gst') ||
//           lower.contains('vat') ||
//           lower.contains('change') ||
//           lower.contains('discount') ||
//           lower.contains('savings') ||
//           lower.contains('refund')) {
//         continue;
//       }

//       final matches = amountRegex.allMatches(line);
//       for (final m in matches) {
//         final parsed = _tryParseReceiptAmount(m.group(0)!);
//         if (parsed != null && parsed > 0) {
//           candidates.add(parsed);
//         }
//       }
//     }

//     if (candidates.isNotEmpty) {
//       candidates.sort();
//       return candidates.last;
//     }

//     return null;
//   }

//   DateTime? _extractBestDateFromReceipt(String text) {
//     final normalized = _normalizeReceiptText(text);

//     final lines = normalized
//         .split('\n')
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();

//     final dateLabelRegex = RegExp(
//       r'(date|date/time|invoice date|transaction date)',
//       caseSensitive: false,
//     );

//     for (final line in lines) {
//       if (dateLabelRegex.hasMatch(line)) {
//         final parsed = _parseDate(line);
//         if (parsed != null) return parsed;
//       }
//     }

//     final patterns = [
//       RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}'),
//       RegExp(r'\d{2}\.\d{2}\.\d{2,4}'),
//       RegExp(r'\d{4}-\d{2}-\d{2}'),
//     ];

//     for (final line in lines) {
//       for (final pattern in patterns) {
//         final match = pattern.firstMatch(line);
//         if (match != null) {
//           final parsed = _parseDate(match.group(0)!);
//           if (parsed != null) return parsed;
//         }
//       }
//     }

//     return null;
//   }

//   DateTime? _extractDueDateFromReceipt(String text) {
//     final lines = text
//         .split('\n')
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();

//     const dueKeywords = [
//       'due date',
//       'payment due',
//       'due by',
//       'pay by',
//       'pay before',
//       'amount due',
//       'balance due',
//       'due on',
//     ];

//     for (final line in lines) {
//       final lower = line.toLowerCase();

//       for (final keyword in dueKeywords) {
//         if (lower.contains(keyword)) {
//           final parsed = _parseDate(line);
//           if (parsed != null) return parsed;
//         }
//       }
//     }

//     return null;
//   }

//   bool _detectIfPaid(String text) {
//     final lower = text.toLowerCase();

//     const unpaidKeywords = [
//       'amount due',
//       'balance due',
//       'payment due',
//       'due date',
//       'due by',
//       'pay by',
//       'pending',
//       'invoice',
//       'statement',
//     ];

//     const paidKeywords = [
//       'approved',
//       'paid',
//       'paid in full',
//       'payment received',
//       'completed',
//       'thank you for your purchase',
//       'visa',
//       'mastercard',
//       'debit',
//       'credit',
//       'cash',
//       'transaction id',
//       'auth code',
//       'authorization',
//       'change',
//       'tender',
//     ];

//     for (final keyword in unpaidKeywords) {
//       if (lower.contains(keyword)) return false;
//     }

//     for (final keyword in paidKeywords) {
//       if (lower.contains(keyword)) return true;
//     }

//     return false;
//   }

//   String? _detectPaymentMethodFromReceipt(String text) {
//     final lower = text.toLowerCase();

//     if (lower.contains('debit')) return 'Debit';
//     if (lower.contains('credit') ||
//         lower.contains('visa') ||
//         lower.contains('mastercard') ||
//         lower.contains('amex')) {
//       return 'Credit';
//     }
//     if (lower.contains('cash')) return 'Cash';
//     if (lower.contains('online') ||
//         lower.contains('paypal') ||
//         lower.contains('e-transfer') ||
//         lower.contains('etransfer')) {
//       return 'Online';
//     }

//     return null;
//   }

//   String? _extractBestLocationFromReceipt(String text) {
//     final lines = text
//         .split('\n')
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();

//     final addressCandidates = <String>[];

//     for (final line in lines) {
//       final lower = line.toLowerCase();

//       final looksLikeZipCity =
//           RegExp(r'\b\d{5}(?:-\d{4})?\b').hasMatch(line) ||
//           RegExp(r'\b\d{4,6}\b').hasMatch(line);

//       final looksLikeStreet =
//           lower.contains('street') ||
//           lower.contains('st.') ||
//           lower.contains('st ') ||
//           lower.contains('road') ||
//           lower.contains('rd') ||
//           lower.contains('ave') ||
//           lower.contains('avenue') ||
//           lower.contains('blvd') ||
//           lower.contains('drive') ||
//           lower.contains('dr ') ||
//           lower.contains('lane') ||
//           lower.contains('ln ') ||
//           lower.contains('finch avenue') ||
//           lower.contains('scarborough');

//       if (looksLikeStreet || looksLikeZipCity) {
//         addressCandidates.add(line);
//       }
//     }

//     if (addressCandidates.isEmpty) return null;
//     return addressCandidates.take(2).join(', ');
//   }

//   String _inferCategoryFromReceipt(String text) {
//     final lower = text.toLowerCase();

//     if (lower.contains('restaurant') ||
//         lower.contains('cafe') ||
//         lower.contains('latte') ||
//         lower.contains('macchiato') ||
//         lower.contains('pizza') ||
//         lower.contains('burger') ||
//         lower.contains('food') ||
//         lower.contains('bar') ||
//         lower.contains('hotel') ||
//         lower.contains('supermarket') ||
//         lower.contains('grocery') ||
//         lower.contains('eggplant') ||
//         lower.contains('onion') ||
//         lower.contains('mango') ||
//         lower.contains('pumpkin') ||
//         lower.contains('bittermelon') ||
//         lower.contains('drumstick') ||
//         lower.contains('longbean') ||
//         lower.contains('ash plant')) {
//       return 'Food';
//     }

//     if (lower.contains('uber') ||
//         lower.contains('taxi') ||
//         lower.contains('transit') ||
//         lower.contains('bus') ||
//         lower.contains('train') ||
//         lower.contains('metro') ||
//         lower.contains('gas') ||
//         lower.contains('fuel') ||
//         lower.contains('parking') ||
//         lower.contains('post') ||
//         lower.contains('parcel') ||
//         lower.contains('mail')) {
//       return 'Transport';
//     }

//     if (lower.contains('walmart') ||
//         lower.contains('store') ||
//         lower.contains('market') ||
//         lower.contains('mall') ||
//         lower.contains('purchase') ||
//         lower.contains('shopping')) {
//       return 'Shopping';
//     }

//     if (lower.contains('netflix') ||
//         lower.contains('spotify') ||
//         lower.contains('cinema') ||
//         lower.contains('movie') ||
//         lower.contains('game')) {
//       return 'Entertainment';
//     }

//     if (lower.contains('pharmacy') ||
//         lower.contains('clinic') ||
//         lower.contains('hospital') ||
//         lower.contains('medical') ||
//         lower.contains('drug')) {
//       return 'Health';
//     }

//     if (lower.contains('hydro') ||
//         lower.contains('electric') ||
//         lower.contains('internet') ||
//         lower.contains('phone bill') ||
//         lower.contains('insurance')) {
//       return 'Bills';
//     }

//     return 'Other';
//   }

//   Future<void> _extractExpenseFieldsFromRecognizedText(
//     RecognizedText recognizedText,
//   ) async {
//     final normalizedText = _normalizeReceiptText(
//       _buildReadableReceiptText(recognizedText),
//     );

//     if (normalizedText.isEmpty) return;

//     final bestTitle = _extractBestTitleFromRecognizedText(recognizedText);
//     if (bestTitle != null && bestTitle.trim().isNotEmpty) {
//       _titleCtrl.text = bestTitle;
//     }

//     final bestAmount = _extractBestAmountFromReceipt(normalizedText);
//     if (bestAmount != null) {
//       _amountCtrl.text = bestAmount.toStringAsFixed(2);
//     }

//     final bestDate = _extractBestDateFromReceipt(normalizedText);
//     if (bestDate != null) {
//       _date = bestDate;
//     }

//     final detectedDueDate = _extractDueDateFromReceipt(normalizedText);
//     if (detectedDueDate != null) {
//       _dueDate = detectedDueDate;
//       _isPaid = false;
//     } else {
//       _isPaid = _detectIfPaid(normalizedText);
//     }

//     final detectedPaymentMethod = _detectPaymentMethodFromReceipt(
//       normalizedText,
//     );
//     if (detectedPaymentMethod != null) {
//       _selectedPayment = detectedPaymentMethod;
//     }

//     _descCtrl.text = normalizedText;
//     _showDescription = normalizedText.isNotEmpty;

//     final bestLocation = _extractBestLocationFromReceipt(normalizedText);
//     if (bestLocation != null && bestLocation.trim().isNotEmpty) {
//       _locationCtrl.text = bestLocation;
//       await _searchAndSelectLocation(bestLocation);
//     }

//     _selectedCategory = _inferCategoryFromReceipt(normalizedText);

//     if (mounted) {
//       setState(() {
//         _scannedRawText = normalizedText;
//       });
//     }
//   }

//   Future<void> _searchAndSelectLocation(String query) async {
//     final trimmed = query.trim();
//     if (trimmed.length < 3) return;

//     setState(() {
//       _isSearchingLocation = true;
//       _locationError = null;
//     });

//     try {
//       final results = await locationFromAddress(trimmed);

//       if (results.isEmpty) {
//         if (!mounted) return;
//         setState(() {
//           _locationPoint = null;
//           _locationError = 'No matching locations found';
//           _isSearchingLocation = false;
//         });
//         return;
//       }

//       final first = results.first;
//       final point = LatLng(first.latitude, first.longitude);

//       if (!mounted) return;
//       setState(() {
//         _locationPoint = point;
//         _locationError = null;
//         _isSearchingLocation = false;
//       });

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         try {
//           _mapController.move(point, 15);
//         } catch (_) {}
//       });
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         _locationPoint = null;
//         _locationError = 'Could not find location';
//         _isSearchingLocation = false;
//       });
//     }
//   }

//   Future<void> _pickDate() async {
//     HapticFeedback.selectionClick();

//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _date ?? now,
//       firstDate: DateTime(now.year - 5),
//       lastDate: DateTime(now.year + 5),
//     );

//     if (picked != null) {
//       HapticFeedback.lightImpact();
//       setState(() => _date = picked);
//     }
//   }

//   Future<void> _pickDueDate() async {
//     HapticFeedback.selectionClick();

//     final now = DateTime.now();
//     final initialDate = _dueDate ?? _date ?? now;
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(now.year - 5),
//       lastDate: DateTime(now.year + 10),
//     );

//     if (picked != null) {
//       HapticFeedback.lightImpact();
//       setState(() => _dueDate = picked);
//     }
//   }

//   String _getFrequencyLabel(RecurringFrequency freq) {
//     switch (freq) {
//       case RecurringFrequency.daily:
//         return 'every day';
//       case RecurringFrequency.biDaily:
//         return 'every other day';
//       case RecurringFrequency.monthly:
//         return 'monthly';
//       case RecurringFrequency.yearly:
//         return 'yearly';
//       default:
//         return 'as scheduled';
//     }
//   }

//   Future<void> _showRecurringFrequencyPicker() async {
//     final frequency = await showModalBottomSheet<RecurringFrequency>(
//       context: context,
//       builder: (context) {
//         return SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'How often should this repeat?',
//                   style: Theme.of(context).textTheme.headlineSmall,
//                 ),
//                 const SizedBox(height: 16),
//                 ListTile(
//                   title: const Text('Every Day'),
//                   onTap: () => Navigator.pop(context, RecurringFrequency.daily),
//                 ),
//                 ListTile(
//                   title: const Text('Every Other Day'),
//                   onTap: () =>
//                       Navigator.pop(context, RecurringFrequency.biDaily),
//                 ),
//                 ListTile(
//                   title: const Text('Once a Month'),
//                   onTap: () =>
//                       Navigator.pop(context, RecurringFrequency.monthly),
//                 ),
//                 ListTile(
//                   title: const Text('Once a Year'),
//                   onTap: () =>
//                       Navigator.pop(context, RecurringFrequency.yearly),
//                 ),
//                 const SizedBox(height: 8),
//               ],
//             ),
//           ),
//         );
//       },
//     );

//     if (frequency != null) {
//       setState(() {
//         _selectedFrequency = frequency;
//       });
//     }
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;

//     final amount = double.tryParse(_amountCtrl.text.trim());
//     if (amount == null || amount <= 0) {
//       HapticFeedback.heavyImpact();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Amount must be greater than 0')),
//       );
//       return;
//     }

//     final expense = Expense(
//       id: _isEditing ? widget.initialExpense!.id : null,
//       title: _titleCtrl.text.trim(),
//       amount: amount,
//       category: _selectedCategory,
//       date: _date,
//       dueDate: _dueDate,
//       description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
//       paymentMethod: _selectedPayment,
//       location: _locationCtrl.text.trim().isEmpty
//           ? null
//           : _locationCtrl.text.trim(),
//       isPaid: _isPaid,
//     );

//     if (_isEditing) {
//       await ExpenseDatabase.instance.updateExpense(expense);
//     } else {
//       await ExpenseDatabase.instance.insertExpense(expense);

//       if (_isRecurring && _selectedFrequency != null) {
//         final recurringExpense = RecurringExpense(
//           title: _titleCtrl.text.trim(),
//           amount: amount,
//           category: _selectedCategory,
//           paymentMethod: _selectedPayment,
//           description: _descCtrl.text.trim().isEmpty
//               ? null
//               : _descCtrl.text.trim(),
//           location: _locationCtrl.text.trim().isEmpty
//               ? null
//               : _locationCtrl.text.trim(),
//           startDate: _date ?? DateTime.now(),
//           frequency: _selectedFrequency!,
//           nextDueDate: _date ?? DateTime.now(),
//         );

//         await ExpenseDatabase.instance.insertRecurringExpense(recurringExpense);
//       }
//     }

//     HapticFeedback.mediumImpact();
//     if (!mounted) return;
//     Navigator.pop(context, true);
//   }

//   Widget _buildMiniFab({
//     required IconData icon,
//     required String heroTag,
//     required VoidCallback onPressed,
//   }) {
//     return ScaleTransition(
//       scale: _fabAnimation,
//       child: FloatingActionButton.small(
//         heroTag: heroTag,
//         onPressed: onPressed,
//         child: Icon(icon),
//       ),
//     );
//   }

//   Widget _buildRecurringSection(ColorScheme scheme) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: scheme.primary.withValues(alpha: 0.3),
//           width: 1.5,
//         ),
//         borderRadius: BorderRadius.circular(14),
//         color: _isRecurring
//             ? scheme.primary.withValues(alpha: 0.08)
//             : Colors.transparent,
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Recurring Payment',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w800,
//                     color: scheme.onSurface,
//                   ),
//                 ),
//                 if (_isRecurring && _selectedFrequency != null) ...[
//                   const SizedBox(height: 4),
//                   Text(
//                     'Repeats ${_getFrequencyLabel(_selectedFrequency!)}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: scheme.onSurfaceVariant,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           SizedBox(
//             width: 110,
//             child: !_isRecurring
//                 ? OutlinedButton(
//                     onPressed: () async {
//                       HapticFeedback.selectionClick();
//                       setState(() => _isRecurring = true);
//                       await _showRecurringFrequencyPicker();
//                     },
//                     child: const Text('Enable'),
//                   )
//                 : OutlinedButton(
//                     onPressed: () {
//                       HapticFeedback.selectionClick();
//                       setState(() {
//                         _isRecurring = false;
//                         _selectedFrequency = null;
//                       });
//                     },
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: scheme.error,
//                       side: BorderSide(color: scheme.error),
//                     ),
//                     child: const Text('Disable'),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           _isEditing
//               ? 'Edit Expense'
//               : (widget.duplicateMode ? 'Duplicate Expense' : 'Add Expense'),
//         ),
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       TextFormField(
//                         controller: _titleCtrl,
//                         textInputAction: TextInputAction.next,
//                         decoration: const InputDecoration(
//                           labelText: 'Title',
//                           prefixIcon: Icon(Icons.title),
//                         ),
//                         validator: (v) {
//                           if (v == null || v.trim().isEmpty) {
//                             return 'Title is required';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _amountCtrl,
//                         keyboardType: const TextInputType.numberWithOptions(
//                           decimal: true,
//                         ),
//                         textInputAction: TextInputAction.next,
//                         decoration: const InputDecoration(
//                           labelText: 'Amount',
//                           hintText: 'e.g., 12.50',
//                           prefixIcon: Icon(Icons.attach_money),
//                         ),
//                         validator: (v) {
//                           if (v == null || v.trim().isEmpty) {
//                             return 'Amount is required';
//                           }
//                           return null;
//                         },
//                       ),
//                       if (_isScanningReceipt) ...[
//                         const SizedBox(height: 12),
//                         const Row(
//                           children: [
//                             SizedBox(
//                               width: 18,
//                               height: 18,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             ),
//                             SizedBox(width: 10),
//                             Text(
//                               'Scanning receipt...',
//                               style: TextStyle(fontWeight: FontWeight.w700),
//                             ),
//                           ],
//                         ),
//                       ],
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _locationCtrl,
//                         textInputAction: TextInputAction.search,
//                         decoration: InputDecoration(
//                           labelText: 'Location (optional)',
//                           prefixIcon: const Icon(Icons.location_on_outlined),
//                           suffixIcon: _isSearchingLocation
//                               ? const Padding(
//                                   padding: EdgeInsets.all(12),
//                                   child: SizedBox(
//                                     width: 18,
//                                     height: 18,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                     ),
//                                   ),
//                                 )
//                               : (_locationPoint != null
//                                   ? const Icon(Icons.check_circle_outline)
//                                   : null),
//                         ),
//                         onChanged: _onLocationChanged,
//                         onFieldSubmitted: (value) async {
//                           await _searchAndSelectLocation(value);
//                         },
//                       ),
//                       const SizedBox(height: 10),
//                       SizedBox(
//                         width: double.infinity,
//                         child: OutlinedButton.icon(
//                           onPressed: () async {
//                             await _searchAndSelectLocation(_locationCtrl.text);
//                           },
//                           icon: const Icon(Icons.search),
//                           label: const Text('Search Location'),
//                         ),
//                       ),
//                       if (_locationError != null) ...[
//                         const SizedBox(height: 8),
//                         Text(
//                           _locationError!,
//                           style: TextStyle(
//                             color: scheme.error,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                       if (_locationPoint != null) ...[
//                         const SizedBox(height: 12),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: SizedBox(
//                             height: 220,
//                             width: double.infinity,
//                             child: FlutterMap(
//                               mapController: _mapController,
//                               options: MapOptions(
//                                 initialCenter: _locationPoint!,
//                                 initialZoom: 15,
//                               ),
//                               children: [
//                                 TileLayer(
//                                   urlTemplate:
//                                       'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
//                                   userAgentPackageName: 'com.example.app',
//                                 ),
//                                 MarkerLayer(
//                                   markers: [
//                                     Marker(
//                                       point: _locationPoint!,
//                                       width: 44,
//                                       height: 44,
//                                       child: const Icon(
//                                         Icons.location_pin,
//                                         size: 44,
//                                         color: Colors.red,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                       if (_scannedRawText != null &&
//                           _scannedRawText!.trim().isNotEmpty) ...[
//                         const SizedBox(height: 12),
//                         Text(
//                           'Scanned Text Preview',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w800,
//                             color: scheme.onSurface,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: scheme.surfaceContainerHighest.withValues(
//                               alpha: 0.45,
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             _scannedRawText!,
//                             maxLines: 12,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               color: scheme.onSurfaceVariant,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                       const SizedBox(height: 16),
//                       Text(
//                         'Category',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w900,
//                           color: scheme.onSurface,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: _categories.map((c) {
//                           final selected = _selectedCategory == c;
//                           return ChoiceChip(
//                             label: Text(c),
//                             selected: selected,
//                             onSelected: (_) {
//                               HapticFeedback.selectionClick();
//                               setState(() => _selectedCategory = c);
//                             },
//                           );
//                         }).toList(),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Payment',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w900,
//                           color: scheme.onSurface,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: _paymentMethods.map((p) {
//                           final selected = _selectedPayment == p;
//                           return ChoiceChip(
//                             label: Text(p),
//                             selected: selected,
//                             onSelected: (_) {
//                               HapticFeedback.selectionClick();
//                               setState(() => _selectedPayment = p);
//                             },
//                           );
//                         }).toList(),
//                       ),
//                       const SizedBox(height: 16),
//                       _buildRecurringSection(scheme),
//                       const SizedBox(height: 16),
//                       SizedBox(
//                         width: double.infinity,
//                         child: OutlinedButton.icon(
//                           onPressed: _pickDate,
//                           icon: const Icon(Icons.calendar_month_outlined),
//                           label: Text(
//                             _date == null
//                                 ? 'Pick date'
//                                 : 'Date: ${_date!.toLocal().toString().split(' ').first}',
//                             style: const TextStyle(fontWeight: FontWeight.w800),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       SizedBox(
//                         width: double.infinity,
//                         child: OutlinedButton.icon(
//                           onPressed: _pickDueDate,
//                           icon: const Icon(Icons.event_available_outlined),
//                           label: Text(
//                             _dueDate == null
//                                 ? 'Pick due date (optional)'
//                                 : 'Due Date: ${_dueDate!.toLocal().toString().split(' ').first}',
//                             style: const TextStyle(fontWeight: FontWeight.w800),
//                           ),
//                         ),
//                       ),
//                       if (_dueDate != null) ...[
//                         const SizedBox(height: 8),
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton.icon(
//                             onPressed: () {
//                               HapticFeedback.selectionClick();
//                               setState(() => _dueDate = null);
//                             },
//                             icon: const Icon(Icons.close),
//                             label: const Text('Clear due date'),
//                           ),
//                         ),
//                       ],
//                       const SizedBox(height: 10),
//                       CheckboxListTile(
//                         contentPadding: EdgeInsets.zero,
//                         value: _isPaid,
//                         onChanged: (value) {
//                           HapticFeedback.selectionClick();
//                           setState(() => _isPaid = value ?? false);
//                         },
//                         title: const Text(
//                           'Mark as already paid',
//                           style: TextStyle(fontWeight: FontWeight.w800),
//                         ),
//                         subtitle: const Text(
//                           'Turn this on if you already settled this expense.',
//                         ),
//                         controlAffinity: ListTileControlAffinity.leading,
//                       ),
//                       const SizedBox(height: 10),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               'Add description',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w800,
//                                 color: scheme.onSurface,
//                               ),
//                             ),
//                           ),
//                           Switch(
//                             value: _showDescription,
//                             onChanged: (v) {
//                               HapticFeedback.selectionClick();
//                               setState(() => _showDescription = v);
//                             },
//                           ),
//                         ],
//                       ),
//                       AnimatedSize(
//                         duration: const Duration(milliseconds: 200),
//                         curve: Curves.easeOut,
//                         child: _showDescription
//                             ? Column(
//                                 children: [
//                                   const SizedBox(height: 6),
//                                   TextFormField(
//                                     controller: _descCtrl,
//                                     maxLines: 3,
//                                     decoration: const InputDecoration(
//                                       labelText: 'Description (optional)',
//                                       prefixIcon: Icon(Icons.notes_outlined),
//                                     ),
//                                   ),
//                                 ],
//                               )
//                             : const SizedBox.shrink(),
//                       ),
//                       const SizedBox(height: 18),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           onPressed: _save,
//                           icon: const Icon(Icons.save),
//                           label: const Text('Save Expense'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: _isEditing
//           ? null
//           : Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 if (_isFabOpen) ...[
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         margin: const EdgeInsets.only(right: 8),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: scheme.surface,
//                           borderRadius: BorderRadius.circular(10),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.08),
//                               blurRadius: 8,
//                             ),
//                           ],
//                         ),
//                         child: const Text(
//                           'Import File',
//                           style: TextStyle(fontWeight: FontWeight.w700),
//                         ),
//                       ),
//                       _buildMiniFab(
//                         icon: Icons.description_outlined,
//                         heroTag: 'file_fab',
//                         onPressed: _onFileTap,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         margin: const EdgeInsets.only(right: 8),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: scheme.surface,
//                           borderRadius: BorderRadius.circular(10),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.08),
//                               blurRadius: 8,
//                             ),
//                           ],
//                         ),
//                         child: const Text(
//                           'Scan Receipt',
//                           style: TextStyle(fontWeight: FontWeight.w700),
//                         ),
//                       ),
//                       _buildMiniFab(
//                         icon: Icons.camera_alt_outlined,
//                         heroTag: 'camera_fab',
//                         onPressed: _onCameraTap,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                 ],
//                 FloatingActionButton(
//                   heroTag: 'main_expandable_fab',
//                   onPressed: _toggleFab,
//                   child: AnimatedRotation(
//                     turns: _isFabOpen ? 0.125 : 0,
//                     duration: const Duration(milliseconds: 220),
//                     child: Icon(_isFabOpen ? Icons.close : Icons.add),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }
import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'database/expense_database.dart';
import 'models/expense.dart';

class AddExpensePage extends StatefulWidget {
  final Expense? initialExpense;
  final bool duplicateMode;

  const AddExpensePage({
    super.key,
    this.initialExpense,
    this.duplicateMode = false,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _date = DateTime.now();
  DateTime? _dueDate;
  bool _isPaid = false;
  bool _isRecurring = false;
  RecurringFrequency? _selectedFrequency;

  final List<String> _categories = const [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Entertainment',
    'Health',
    'Other',
  ];

  final List<String> _paymentMethods = const [
    'Cash',
    'Debit',
    'Credit',
    'Online',
  ];

  String _selectedCategory = 'Food';
  String _selectedPayment = 'Debit';
  bool _showDescription = false;

  bool _isFabOpen = false;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  final MapController _mapController = MapController();
  LatLng? _locationPoint;
  bool _isSearchingLocation = false;
  String? _locationError;
  Timer? _locationDebounce;
  List<_LocationSuggestion> _locationSuggestions = [];
  bool _showLocationSuggestions = false;

  bool _isScanningReceipt = false;
  String? _scannedRawText;

  bool get _isEditing =>
      widget.initialExpense != null && widget.duplicateMode == false;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOut,
    );

    _recoverLostCameraImage();

    final initial = widget.initialExpense;
    if (initial != null) {
      _titleCtrl.text = initial.title;
      _amountCtrl.text = initial.amount.toStringAsFixed(2);
      _descCtrl.text = initial.description ?? '';
      _locationCtrl.text = initial.location ?? '';
      _date = initial.date ?? DateTime.now();
      _dueDate = initial.dueDate;
      _selectedCategory = _categories.contains(initial.category)
          ? initial.category
          : 'Other';
      _selectedPayment = _paymentMethods.contains(initial.paymentMethod)
          ? initial.paymentMethod
          : 'Cash';
      _showDescription = _descCtrl.text.trim().isNotEmpty;
      _isPaid = widget.duplicateMode ? false : initial.isPaid;

      if ((initial.location ?? '').trim().isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _searchAndSelectLocation(initial.location!);
        });
      }
    }
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    HapticFeedback.selectionClick();
    setState(() {
      _isFabOpen = !_isFabOpen;
    });

    if (_isFabOpen) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  String _normalizeLocationQuery(String input) {
    var text = input.trim();

    final replacements = <String, String>{
      'tornto': 'toronto',
      'toronot': 'toronto',
      'scarborugh': 'scarborough',
      'scarbrough': 'scarborough',
      'missisauga': 'mississauga',
      'bramton': 'brampton',
      'vancover': 'vancouver',
      'montreall': 'montreal',
      'avnue': 'avenue',
      'aveune': 'avenue',
      'stret': 'street',
      'streeet': 'street',
      'roaad': 'road',
      'boulvard': 'boulevard',
    };

    replacements.forEach((wrong, correct) {
      text = text.replaceAll(
        RegExp('\\b$wrong\\b', caseSensitive: false),
        correct,
      );
    });

    text = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' ,', ',')
        .trim();

    return text;
  }

  String _buildPlacemarkLabel(Placemark place) {
    final parts = <String>[
      if ((place.name ?? '').trim().isNotEmpty) place.name!.trim(),
      if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
      if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
      if ((place.administrativeArea ?? '').trim().isNotEmpty)
        place.administrativeArea!.trim(),
      if ((place.postalCode ?? '').trim().isNotEmpty) place.postalCode!.trim(),
      if ((place.country ?? '').trim().isNotEmpty) place.country!.trim(),
    ];

    final unique = <String>[];
    for (final part in parts) {
      if (!unique.contains(part)) {
        unique.add(part);
      }
    }

    return unique.join(', ');
  }

  Future<void> _fetchLocationSuggestions(String query) async {
    final trimmed = query.trim();

    if (trimmed.length < 3) {
      if (!mounted) return;
      setState(() {
        _locationSuggestions = [];
        _showLocationSuggestions = false;
        _locationError = null;
        _isSearchingLocation = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearchingLocation = true;
      _locationError = null;
    });

    final attempts = <String>{
      trimmed,
      _normalizeLocationQuery(trimmed),
      _normalizeLocationQuery(trimmed)
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    }.where((e) => e.length >= 3).toList();

    try {
      final uniqueResults = <Location>[];
      final seenCoords = <String>{};

      for (final attempt in attempts) {
        try {
          final rawResults = await locationFromAddress(attempt);

          for (final result in rawResults) {
            final key =
                '${result.latitude.toStringAsFixed(5)},${result.longitude.toStringAsFixed(5)}';
            if (seenCoords.add(key)) {
              uniqueResults.add(result);
            }
            if (uniqueResults.length >= 5) break;
          }

          if (uniqueResults.isNotEmpty) {
            break;
          }
        } catch (_) {
          // try next attempt
        }
      }

      if (uniqueResults.isEmpty) {
        if (!mounted) return;
        setState(() {
          _locationSuggestions = [];
          _showLocationSuggestions = false;
          _locationError = 'No matching locations found';
          _isSearchingLocation = false;
        });
        return;
      }

      final suggestions = <_LocationSuggestion>[];

      for (final result in uniqueResults) {
        String label =
            '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';

        try {
          final placemarks = await placemarkFromCoordinates(
            result.latitude,
            result.longitude,
          );
          if (placemarks.isNotEmpty) {
            final built = _buildPlacemarkLabel(placemarks.first);
            if (built.trim().isNotEmpty) {
              label = built;
            }
          }
        } catch (_) {}

        suggestions.add(
          _LocationSuggestion(
            label: label,
            point: LatLng(result.latitude, result.longitude),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _locationSuggestions = suggestions;
        _showLocationSuggestions = suggestions.isNotEmpty;
        _locationError =
            suggestions.isEmpty ? 'No matching locations found' : null;
        _isSearchingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationSuggestions = [];
        _showLocationSuggestions = false;
        _locationError = 'Could not fetch location suggestions';
        _isSearchingLocation = false;
      });
    }
  }

  void _onLocationChanged(String value) {
    _locationDebounce?.cancel();

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      if (!mounted) return;
      setState(() {
        _locationPoint = null;
        _locationError = null;
        _isSearchingLocation = false;
        _locationSuggestions = [];
        _showLocationSuggestions = false;
      });
      return;
    }

    if (trimmed.length < 3) {
      if (!mounted) return;
      setState(() {
        _locationError = null;
        _locationSuggestions = [];
        _showLocationSuggestions = false;
      });
      return;
    }

    _locationDebounce = Timer(const Duration(milliseconds: 650), () async {
      if (!mounted) return;
      await _fetchLocationSuggestions(trimmed);
    });
  }

  void _selectLocationSuggestion(_LocationSuggestion suggestion) {
    _locationDebounce?.cancel();

    _locationCtrl.text = suggestion.label;
    _locationCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _locationCtrl.text.length),
    );

    if (!mounted) return;
    setState(() {
      _locationPoint = suggestion.point;
      _locationError = null;
      _locationSuggestions = [];
      _showLocationSuggestions = false;
      _isSearchingLocation = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(suggestion.point, 15);
      } catch (_) {}
    });
  }

  Future<void> _recoverLostCameraImage() async {
    try {
      final LostDataResponse response = await _imagePicker.retrieveLostData();

      if (response.isEmpty) return;

      if (response.files != null && response.files!.isNotEmpty) {
        await _processPickedReceiptFile(response.files!.first);
        return;
      }

      if (response.file != null) {
        await _processPickedReceiptFile(response.file!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to recover camera image: $e')),
      );
    }
  }

  Future<void> _processPickedReceiptFile(XFile pickedFile) async {
    TextRecognizer? textRecognizer;

    try {
      if (!mounted) return;

      setState(() {
        _isScanningReceipt = true;
        _scannedRawText = null;
      });

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final recognizedText = await textRecognizer.processImage(inputImage);
      final rebuiltText = _buildReadableReceiptText(recognizedText);

      if (!mounted) return;
      setState(() {
        _scannedRawText = rebuiltText;
      });

      await _extractExpenseFieldsFromRecognizedText(recognizedText);

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rebuiltText.isEmpty
                ? 'Scan finished, but no text was detected'
                : 'Receipt scanned successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
    } finally {
      try {
        await textRecognizer?.close();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isScanningReceipt = false;
        });
      }
    }
  }

  Future<void> _onCameraTap() async {
    if (_isScanningReceipt) return;

    HapticFeedback.lightImpact();

    if (mounted) {
      setState(() {
        _isFabOpen = false;
      });
    }
    _fabController.reverse();

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
       imageQuality: 95,
        maxWidth: 1280,
        maxHeight: 1280,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null) return;
      await Future.delayed(const Duration(milliseconds: 500));
      await _processPickedReceiptFile(pickedFile);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
    }
  }

  Future<void> _onFileTap() async {
    HapticFeedback.lightImpact();

    setState(() {
      _isFabOpen = false;
    });
    _fabController.reverse();

    await _importExpenseFile();
  }

  Future<void> _importExpenseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      final path = picked.path;
      if (path == null) {
        throw Exception('Unable to read selected file path.');
      }

      final extension = (picked.extension ?? '').toLowerCase();
      final file = File(path);

      List<Map<String, dynamic>> rows = [];

      if (extension == 'csv') {
        final input = await file.readAsString();
        final csvTable = const CsvToListConverter().convert(input);

        if (csvTable.isEmpty) {
          throw Exception('CSV file is empty.');
        }

        final headers = csvTable.first
            .map((e) => e.toString().trim().toLowerCase())
            .toList();

        for (int i = 1; i < csvTable.length; i++) {
          final row = csvTable[i];
          if (_isRowCompletelyEmpty(row)) continue;

          final data = <String, dynamic>{};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            data[headers[j]] = row[j];
          }

          if (!_looksLikeExpenseRow(data)) continue;
          rows.add(data);
        }
      } else if (extension == 'xlsx' || extension == 'xls') {
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);

        if (excel.tables.isEmpty) {
          throw Exception('Excel file has no sheets.');
        }

        final sheet = excel.tables.values.first;
        if (sheet.rows.isEmpty) {
          throw Exception('Excel sheet is empty.');
        }

        final headers = sheet.rows.first
            .map((cell) => cell?.value.toString().trim().toLowerCase() ?? '')
            .toList();

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (_isExcelRowEmpty(row)) continue;

          final data = <String, dynamic>{};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            data[headers[j]] = row[j]?.value;
          }

          if (!_looksLikeExpenseRow(data)) continue;
          rows.add(data);
        }
      } else {
        throw Exception('Unsupported file type.');
      }

      final toImport = <Expense>[];

      for (final row in rows) {
        final amount = _parseAmount(
          _readAny(row, const [
            'amount',
            'cost',
            'price',
            'expense',
            r'$',
            'total',
          ]),
        );

        if (amount == null || amount <= 0) continue;

        final parsedDate = _parseDate(
          _readAny(row, const ['date', 'expense date', 'day']),
        );

        final description = _stringValue(
          _readAny(row, const ['description', 'details', 'note']),
        );

        final title =
            _stringValue(_readAny(row, const ['title', 'name', 'item'])) ??
            description ??
            'Imported Expense';

        final categoryText = _stringValue(
          _readAny(row, const ['category', 'type']),
        );

        final paymentText = _stringValue(
          _readAny(row, const ['payment', 'payment method', 'method']),
        );

        final locationText = _stringValue(
          _readAny(row, const ['location', 'place', 'store']),
        );

        final combinedText = [
          title,
          if (description != null) description,
          if (locationText != null) locationText,
          if (categoryText != null) categoryText,
        ].join('\n');

        toImport.add(
          Expense(
            title: title,
            amount: amount,
            category:
                _normalizeCategory(categoryText) ??
                _inferCategoryFromReceipt(combinedText),
            date: parsedDate ?? DateTime.now(),
            dueDate: null,
            description: description,
            paymentMethod: _normalizePaymentMethod(paymentText) ?? 'Cash',
            location: locationText,
            isPaid: false,
          ),
        );
      }

      await ExpenseDatabase.instance.insertExpenses(toImport);
      final importedCount = toImport.length;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            importedCount > 0
                ? 'Imported $importedCount expense(s)'
                : 'No valid expense rows found in file',
          ),
        ),
      );

      if (importedCount > 0) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  bool _isRowCompletelyEmpty(List<dynamic> row) {
    for (final cell in row) {
      if (cell != null && cell.toString().trim().isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  bool _isExcelRowEmpty(List<Data?> row) {
    for (final cell in row) {
      if (cell?.value != null && cell!.value.toString().trim().isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  bool _looksLikeExpenseRow(Map<String, dynamic> row) {
    final joined = row.values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');

    if (joined.contains('total expenses') ||
        joined.contains('grand total') ||
        joined.contains('subtotal')) {
      return false;
    }
    return true;
  }

  dynamic _readAny(Map<String, dynamic> row, List<String> possibleKeys) {
    for (final key in possibleKeys) {
      for (final existingKey in row.keys) {
        if (existingKey.trim().toLowerCase() == key.trim().toLowerCase()) {
          return row[existingKey];
        }
      }
    }
    return null;
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  double? _parseAmount(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (cleaned.isEmpty) return null;

    return double.tryParse(cleaned);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    var raw = value.toString().trim();
    if (raw.isEmpty) return null;

    raw = raw.replaceAll('O', '0').replaceAll('o', '0');

    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;

    final match = RegExp(
      r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{2}\.\d{2}\.\d{2,4}|\d{4}-\d{2}-\d{2})',
    ).firstMatch(raw);

    final dateOnly = match != null ? match.group(0)! : raw;

    final slashParts = dateOnly.split('/');
    if (slashParts.length == 3) {
      final month = int.tryParse(slashParts[0]);
      final day = int.tryParse(slashParts[1]);
      var year = int.tryParse(slashParts[2]);

      if (month != null && day != null && year != null) {
        if (year < 100) {
          year += (year >= 70) ? 1900 : 2000;
        }
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }
    }

    final dashParts = dateOnly.split('-');
    if (dashParts.length == 3) {
      final y1 = int.tryParse(dashParts[0]);
      final m1 = int.tryParse(dashParts[1]);
      final d1 = int.tryParse(dashParts[2]);

      if (y1 != null && m1 != null && d1 != null) {
        if (y1 > 999 && m1 >= 1 && m1 <= 12 && d1 >= 1 && d1 <= 31) {
          return DateTime(y1, m1, d1);
        }
      }

      final day = int.tryParse(dashParts[0]);
      final month = int.tryParse(dashParts[1]);
      var year = int.tryParse(dashParts[2]);

      if (day != null && month != null && year != null) {
        if (year < 100) {
          year += (year >= 70) ? 1900 : 2000;
        }
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }
    }

    final dotParts = dateOnly.split('.');
    if (dotParts.length == 3) {
      final day = int.tryParse(dotParts[0]);
      final month = int.tryParse(dotParts[1]);
      var year = int.tryParse(dotParts[2]);

      if (day != null && month != null && year != null) {
        if (year < 100) {
          year += (year >= 70) ? 1900 : 2000;
        }
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  String? _normalizeCategory(dynamic value) {
    final text = _stringValue(value);
    if (text == null) return null;

    for (final category in _categories) {
      if (category.toLowerCase() == text.toLowerCase()) {
        return category;
      }
    }

    return text;
  }

  String? _normalizePaymentMethod(dynamic value) {
    final text = _stringValue(value);
    if (text == null) return null;

    for (final method in _paymentMethods) {
      if (method.toLowerCase() == text.toLowerCase()) {
        return method;
      }
    }

    final lower = text.toLowerCase();
    if (lower.contains('debit')) return 'Debit';
    if (lower.contains('credit')) return 'Credit';
    if (lower.contains('cash')) return 'Cash';
    if (lower.contains('online')) return 'Online';

    return text;
  }

  String _normalizeReceiptText(String text) {
    return text
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('SFr', 'CHF');
  }

  List<String> _extractOrderedLinesFromRecognizedText(RecognizedText text) {
    final lines = <Map<String, dynamic>>[];

    for (final block in text.blocks) {
      for (final line in block.lines) {
        final raw = line.text.trim();
        if (raw.isEmpty) continue;

        lines.add({
          'text': raw,
          'top': line.boundingBox.top.toDouble(),
          'left': line.boundingBox.left.toDouble(),
        });
      }
    }

    if (lines.isEmpty) return [];

    lines.sort((a, b) {
      final double topA = a['top'] as double;
      final double topB = b['top'] as double;
      final double leftA = a['left'] as double;
      final double leftB = b['left'] as double;

      final double topDiff = (topA - topB).abs();
      if (topDiff <= 14) {
        return leftA.compareTo(leftB);
      }
      return topA.compareTo(topB);
    });

    return lines.map((e) => e['text'] as String).toList();
  }

  String _buildReadableReceiptText(RecognizedText text) {
    final orderedLines = _extractOrderedLinesFromRecognizedText(text);
    return orderedLines.join('\n').trim();
  }

  bool _looksLikeHeaderStopLine(String line) {
    final lower = line.toLowerCase().trim();

    return lower.contains('date/time') ||
        lower.startsWith('date') ||
        lower.contains('receipt #') ||
        lower.contains('receipt#:') ||
        lower.contains('station #') ||
        lower.contains('cashier') ||
        lower == 'sale' ||
        lower == 'qty' ||
        lower.contains('qty ') ||
        lower == 'product' ||
        lower == 'price' ||
        lower == 'sum' ||
        (lower.contains('qty') &&
            lower.contains('product') &&
            (lower.contains('price') || lower.contains('sum')));
  }

  bool _isBadMerchantLine(String line) {
    final lower = line.toLowerCase().trim();

    if (lower.isEmpty) return true;

    if (lower.contains('receipt') ||
        lower.contains('invoice') ||
        lower == 'sale' ||
        lower == 'qty' ||
        lower == 'product' ||
        lower == 'price' ||
        lower == 'sum' ||
        lower.contains('date') ||
        lower.contains('time') ||
        lower.contains('station') ||
        lower.contains('cashier') ||
        lower.contains('hst') ||
        lower.contains('gst') ||
        lower.contains('tax') ||
        lower.contains('tel') ||
        lower.contains('fax') ||
        lower.contains('www') ||
        lower.contains('.com') ||
        lower.contains('card transaction record')) {
      return true;
    }

    if (RegExp(r'^\d[\d/\-:. ]+$').hasMatch(lower)) return true;
    if (RegExp(r'^\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}$').hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(lower)) {
      return true;
    }

    return false;
  }

  String _cleanMerchantTitle(String value) {
    var text = value.trim();
    if (text.isEmpty) return text;

    text = text.replaceAll(RegExp(r'\s+'), ' ');
    text = text.replaceAll(
      RegExp(r'(?<=\D)0(?=\D)|(?<=\b)0(?=\D)|(?<=\D)0(?=\b)'),
      'O',
    );

    if (text == text.toUpperCase()) {
      return text
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .map((w) {
            if (w.length == 1) return w.toUpperCase();
            return w[0].toUpperCase() + w.substring(1).toLowerCase();
          })
          .join(' ');
    }

    return text;
  }

  String? _extractBestTitleFromRecognizedText(RecognizedText text) {
    final lines = _extractOrderedLinesFromRecognizedText(text);
    if (lines.isEmpty) return null;

    final topLines = lines.take(10).toList();

    final headerLines = <String>[];
    for (final line in topLines) {
      if (_looksLikeHeaderStopLine(line)) break;
      headerLines.add(line);
    }

    bool looksLikeAddress(String line) {
      final lower = line.toLowerCase();
      return RegExp(r'\d').hasMatch(line) &&
          (lower.contains('avenue') ||
              lower.contains('street') ||
              lower.contains('road') ||
              lower.contains('drive') ||
              lower.contains('blvd') ||
              lower.contains('ont') ||
              lower.contains('scarborough'));
    }

    int scoreLine(String line, int index) {
      int score = 0;
      final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
      final digits = RegExp(r'\d').allMatches(line).length;

      if (index == 0) score += 40;
      if (index == 1) score += 25;
      if (index == 2) score += 12;

      if (letters >= 5) score += 18;
      if (digits == 0) score += 12;
      if (line.length >= 4 && line.length <= 30) score += 14;
      if (line == line.toUpperCase()) score += 6;
      if (looksLikeAddress(line)) score -= 35;
      if (_isBadMerchantLine(line)) score -= 100;

      return score;
    }

    String? bestLine;
    int bestScore = -9999;

    for (int i = 0; i < headerLines.length; i++) {
      final line = headerLines[i];

      final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
      final digits = RegExp(r'\d').allMatches(line).length;

      if (letters < 3) continue;
      if (digits > letters) continue;
      if (_isBadMerchantLine(line)) continue;

      final score = scoreLine(line, i);
      if (score > bestScore) {
        bestScore = score;
        bestLine = line;
      }
    }

    if (bestLine != null && bestLine.trim().isNotEmpty) {
      return _cleanMerchantTitle(
        bestLine.length > 40 ? bestLine.substring(0, 40) : bestLine,
      );
    }

    for (final line in topLines) {
      if (!_isBadMerchantLine(line)) {
        return _cleanMerchantTitle(
          line.length > 40 ? line.substring(0, 40) : line,
        );
      }
    }

    return _cleanMerchantTitle(
      lines.first.length > 40 ? lines.first.substring(0, 40) : lines.first,
    );
  }

  double? _tryParseReceiptAmount(String raw) {
    var cleaned = raw.trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9,.\-]'), '');

    if (cleaned.contains(',') && cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '');
    } else if (cleaned.contains(',') && !cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '.');
    }

    return double.tryParse(cleaned);
  }

  double? _extractBestAmountFromReceipt(String text) {
    final normalized = _normalizeReceiptText(text);

    final lines = normalized
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final amountRegex = RegExp(r'(?<!\d)(\d{1,4}[.,]\d{2})(?!\d)');

    double? parseLastAmount(String line) {
      final matches = amountRegex.allMatches(line).toList();
      if (matches.isEmpty) return null;
      return _tryParseReceiptAmount(matches.last.group(0)!);
    }

    bool containsAny(String line, List<String> keywords) {
      final lower = line.toLowerCase();
      return keywords.any((k) => lower.contains(k));
    }

    bool containsNone(String line, List<String> keywords) {
      final lower = line.toLowerCase();
      return keywords.every((k) => !lower.contains(k));
    }

    const priority1 = [
      'grand total',
      'amount due',
      'balance due',
      'total due',
      'net total',
    ];

    for (final line in lines.reversed) {
      if (containsAny(line, priority1)) {
        final parsed = parseLastAmount(line);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    const excludedTotalWords = [
      'tax',
      'total tax',
      'subtotal',
      'sub total',
      'hst',
      'gst',
      'vat',
      'tip',
      'change',
      'discount',
      'savings',
      'refund',
    ];

    for (final line in lines.reversed) {
      final lower = line.toLowerCase();
      if (lower.contains('total') && containsNone(line, excludedTotalWords)) {
        final parsed = parseLastAmount(line);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    for (final line in lines.reversed.take(12)) {
      final lower = line.toLowerCase();
      if ((lower.contains('approved') ||
              lower.contains('paid') ||
              lower.contains('debit') ||
              lower.contains('credit') ||
              lower.contains('visa') ||
              lower.contains('mastercard')) &&
          !lower.contains('card number')) {
        final parsed = parseLastAmount(line);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    final candidates = <double>[];

    for (final line in lines) {
      final lower = line.toLowerCase();

      if (lower.contains('tax') ||
          lower.contains('hst') ||
          lower.contains('gst') ||
          lower.contains('vat') ||
          lower.contains('change') ||
          lower.contains('discount') ||
          lower.contains('savings') ||
          lower.contains('refund')) {
        continue;
      }

      final matches = amountRegex.allMatches(line);
      for (final m in matches) {
        final parsed = _tryParseReceiptAmount(m.group(0)!);
        if (parsed != null && parsed > 0) {
          candidates.add(parsed);
        }
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort();
      return candidates.last;
    }

    return null;
  }

  DateTime? _extractBestDateFromReceipt(String text) {
    final normalized = _normalizeReceiptText(text);

    final lines = normalized
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final dateLabelRegex = RegExp(
      r'(date|date/time|invoice date|transaction date)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (dateLabelRegex.hasMatch(line)) {
        final parsed = _parseDate(line);
        if (parsed != null) return parsed;
      }
    }

    final patterns = [
      RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}'),
      RegExp(r'\d{2}\.\d{2}\.\d{2,4}'),
      RegExp(r'\d{4}-\d{2}-\d{2}'),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final parsed = _parseDate(match.group(0)!);
          if (parsed != null) return parsed;
        }
      }
    }

    return null;
  }

  DateTime? _extractDueDateFromReceipt(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    const dueKeywords = [
      'due date',
      'payment due',
      'due by',
      'pay by',
      'pay before',
      'amount due',
      'balance due',
      'due on',
    ];

    for (final line in lines) {
      final lower = line.toLowerCase();

      for (final keyword in dueKeywords) {
        if (lower.contains(keyword)) {
          final parsed = _parseDate(line);
          if (parsed != null) return parsed;
        }
      }
    }

    return null;
  }

  bool _detectIfPaid(String text) {
    final lower = text.toLowerCase();

    const unpaidKeywords = [
      'amount due',
      'balance due',
      'payment due',
      'due date',
      'due by',
      'pay by',
      'pending',
      'invoice',
      'statement',
    ];

    const paidKeywords = [
      'approved',
      'paid',
      'paid in full',
      'payment received',
      'completed',
      'thank you for your purchase',
      'visa',
      'mastercard',
      'debit',
      'credit',
      'cash',
      'transaction id',
      'auth code',
      'authorization',
      'change',
      'tender',
    ];

    for (final keyword in unpaidKeywords) {
      if (lower.contains(keyword)) return false;
    }

    for (final keyword in paidKeywords) {
      if (lower.contains(keyword)) return true;
    }

    return false;
  }

  String? _detectPaymentMethodFromReceipt(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('debit')) return 'Debit';
    if (lower.contains('credit') ||
        lower.contains('visa') ||
        lower.contains('mastercard') ||
        lower.contains('amex')) {
      return 'Credit';
    }
    if (lower.contains('cash')) return 'Cash';
    if (lower.contains('online') ||
        lower.contains('paypal') ||
        lower.contains('e-transfer') ||
        lower.contains('etransfer')) {
      return 'Online';
    }

    return null;
  }

  String? _extractBestLocationFromReceipt(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final addressCandidates = <String>[];

    for (final line in lines) {
      final lower = line.toLowerCase();

      final looksLikeZipCity =
          RegExp(r'\b\d{5}(?:-\d{4})?\b').hasMatch(line) ||
          RegExp(r'\b\d{4,6}\b').hasMatch(line);

      final looksLikeStreet =
          lower.contains('street') ||
          lower.contains('st.') ||
          lower.contains('st ') ||
          lower.contains('road') ||
          lower.contains('rd') ||
          lower.contains('ave') ||
          lower.contains('avenue') ||
          lower.contains('blvd') ||
          lower.contains('drive') ||
          lower.contains('dr ') ||
          lower.contains('lane') ||
          lower.contains('ln ') ||
          lower.contains('finch avenue') ||
          lower.contains('scarborough');

      if (looksLikeStreet || looksLikeZipCity) {
        addressCandidates.add(line);
      }
    }

    if (addressCandidates.isEmpty) return null;
    return addressCandidates.take(2).join(', ');
  }

  String _inferCategoryFromReceipt(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('restaurant') ||
        lower.contains('cafe') ||
        lower.contains('latte') ||
        lower.contains('macchiato') ||
        lower.contains('pizza') ||
        lower.contains('burger') ||
        lower.contains('food') ||
        lower.contains('bar') ||
        lower.contains('hotel') ||
        lower.contains('supermarket') ||
        lower.contains('grocery') ||
        lower.contains('eggplant') ||
        lower.contains('onion') ||
        lower.contains('mango') ||
        lower.contains('pumpkin') ||
        lower.contains('bittermelon') ||
        lower.contains('drumstick') ||
        lower.contains('longbean') ||
        lower.contains('ash plant')) {
      return 'Food';
    }

    if (lower.contains('uber') ||
        lower.contains('taxi') ||
        lower.contains('transit') ||
        lower.contains('bus') ||
        lower.contains('train') ||
        lower.contains('metro') ||
        lower.contains('gas') ||
        lower.contains('fuel') ||
        lower.contains('parking') ||
        lower.contains('post') ||
        lower.contains('parcel') ||
        lower.contains('mail')) {
      return 'Transport';
    }

    if (lower.contains('walmart') ||
        lower.contains('store') ||
        lower.contains('market') ||
        lower.contains('mall') ||
        lower.contains('purchase') ||
        lower.contains('shopping')) {
      return 'Shopping';
    }

    if (lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('cinema') ||
        lower.contains('movie') ||
        lower.contains('game')) {
      return 'Entertainment';
    }

    if (lower.contains('pharmacy') ||
        lower.contains('clinic') ||
        lower.contains('hospital') ||
        lower.contains('medical') ||
        lower.contains('drug')) {
      return 'Health';
    }

    if (lower.contains('hydro') ||
        lower.contains('electric') ||
        lower.contains('internet') ||
        lower.contains('phone bill') ||
        lower.contains('insurance')) {
      return 'Bills';
    }

    return 'Other';
  }

  Future<void> _extractExpenseFieldsFromRecognizedText(
    RecognizedText recognizedText,
  ) async {
    final normalizedText = _normalizeReceiptText(
      _buildReadableReceiptText(recognizedText),
    );

    if (normalizedText.isEmpty) return;

    final bestTitle = _extractBestTitleFromRecognizedText(recognizedText);
    if (bestTitle != null && bestTitle.trim().isNotEmpty) {
      _titleCtrl.text = bestTitle;
    }

    final bestAmount = _extractBestAmountFromReceipt(normalizedText);
    if (bestAmount != null) {
      _amountCtrl.text = bestAmount.toStringAsFixed(2);
    }

    final bestDate = _extractBestDateFromReceipt(normalizedText);
    if (bestDate != null) {
      _date = bestDate;
    }

    final detectedDueDate = _extractDueDateFromReceipt(normalizedText);
    if (detectedDueDate != null) {
      _dueDate = detectedDueDate;
      _isPaid = false;
    } else {
      _isPaid = _detectIfPaid(normalizedText);
    }

    final detectedPaymentMethod = _detectPaymentMethodFromReceipt(
      normalizedText,
    );
    if (detectedPaymentMethod != null) {
      _selectedPayment = detectedPaymentMethod;
    }

    _descCtrl.text = normalizedText;
    _showDescription = normalizedText.isNotEmpty;

    final bestLocation = _extractBestLocationFromReceipt(normalizedText);
    if (bestLocation != null && bestLocation.trim().isNotEmpty) {
      _locationCtrl.text = bestLocation;
      await _searchAndSelectLocation(bestLocation);
    }

    _selectedCategory = _inferCategoryFromReceipt(normalizedText);

    if (mounted) {
      setState(() {
        _scannedRawText = normalizedText;
      });
    }
  }

  Future<void> _searchAndSelectLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return;

    final attempts = <String>{
      trimmed,
      _normalizeLocationQuery(trimmed),
      _normalizeLocationQuery(trimmed)
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    }.where((e) => e.length >= 3).toList();

    setState(() {
      _isSearchingLocation = true;
      _locationError = null;
      _showLocationSuggestions = false;
    });

    for (final attempt in attempts) {
      try {
        final results = await locationFromAddress(attempt);

        if (results.isEmpty) {
          continue;
        }

        final first = results.first;
        final point = LatLng(first.latitude, first.longitude);

        String correctedLabel = trimmed;
        try {
          final placemarks = await placemarkFromCoordinates(
            first.latitude,
            first.longitude,
          );
          if (placemarks.isNotEmpty) {
            final built = _buildPlacemarkLabel(placemarks.first);
            if (built.trim().isNotEmpty) {
              correctedLabel = built;
            }
          }
        } catch (_) {}

        if (!mounted) return;
        setState(() {
          _locationCtrl.text = correctedLabel;
          _locationCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _locationCtrl.text.length),
          );
          _locationPoint = point;
          _locationError = null;
          _isSearchingLocation = false;
          _locationSuggestions = [];
          _showLocationSuggestions = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            _mapController.move(point, 15);
          } catch (_) {}
        });
        return;
      } catch (_) {
        // try next attempt
      }
    }

    if (!mounted) return;
    setState(() {
      _locationPoint = null;
      _locationError = 'No matching locations found';
      _isSearchingLocation = false;
      _locationSuggestions = [];
      _showLocationSuggestions = false;
    });
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

  Future<void> _pickDueDate() async {
    HapticFeedback.selectionClick();

    final now = DateTime.now();
    final initialDate = _dueDate ?? _date ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      HapticFeedback.lightImpact();
      setState(() => _dueDate = picked);
    }
  }

  String _getFrequencyLabel(RecurringFrequency freq) {
    switch (freq) {
      case RecurringFrequency.daily:
        return 'every day';
      case RecurringFrequency.biDaily:
        return 'every other day';
      case RecurringFrequency.monthly:
        return 'monthly';
      case RecurringFrequency.yearly:
        return 'yearly';
      default:
        return 'as scheduled';
    }
  }

  Future<void> _showRecurringFrequencyPicker() async {
    final frequency = await showModalBottomSheet<RecurringFrequency>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How often should this repeat?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Every Day'),
                  onTap: () => Navigator.pop(context, RecurringFrequency.daily),
                ),
                ListTile(
                  title: const Text('Every Other Day'),
                  onTap: () =>
                      Navigator.pop(context, RecurringFrequency.biDaily),
                ),
                ListTile(
                  title: const Text('Once a Month'),
                  onTap: () =>
                      Navigator.pop(context, RecurringFrequency.monthly),
                ),
                ListTile(
                  title: const Text('Once a Year'),
                  onTap: () =>
                      Navigator.pop(context, RecurringFrequency.yearly),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (frequency != null) {
      setState(() {
        _selectedFrequency = frequency;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0')),
      );
      return;
    }

    final expense = Expense(
      id: _isEditing ? widget.initialExpense!.id : null,
      title: _titleCtrl.text.trim(),
      amount: amount,
      category: _selectedCategory,
      date: _date,
      dueDate: _dueDate,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      paymentMethod: _selectedPayment,
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      isPaid: _isPaid,
    );

    if (_isEditing) {
      await ExpenseDatabase.instance.updateExpense(expense);
    } else {
      await ExpenseDatabase.instance.insertExpense(expense);

      if (_isRecurring && _selectedFrequency != null) {
        final recurringExpense = RecurringExpense(
          title: _titleCtrl.text.trim(),
          amount: amount,
          category: _selectedCategory,
          paymentMethod: _selectedPayment,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          startDate: _date ?? DateTime.now(),
          frequency: _selectedFrequency!,
          nextDueDate: _date ?? DateTime.now(),
        );

        await ExpenseDatabase.instance.insertRecurringExpense(recurringExpense);
      }
    }

    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _buildMiniFab({
    required IconData icon,
    required String heroTag,
    required VoidCallback onPressed,
  }) {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.small(
        heroTag: heroTag,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }

  Widget _buildRecurringSection(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
        color: _isRecurring
            ? scheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recurring Payment',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                if (_isRecurring && _selectedFrequency != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Repeats ${_getFrequencyLabel(_selectedFrequency!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: !_isRecurring
                ? OutlinedButton(
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      setState(() => _isRecurring = true);
                      await _showRecurringFrequencyPicker();
                    },
                    child: const Text('Enable'),
                  )
                : OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isRecurring = false;
                        _selectedFrequency = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                    ),
                    child: const Text('Disable'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSuggestions(ColorScheme scheme) {
    if (!_showLocationSuggestions || _locationSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _locationSuggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;

          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(
                  suggestion.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _selectLocationSuggestion(suggestion),
              ),
              if (index != _locationSuggestions.length - 1)
                Divider(height: 1, color: scheme.outlineVariant),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit Expense'
              : (widget.duplicateMode ? 'Duplicate Expense' : 'Add Expense'),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_showLocationSuggestions) {
            setState(() {
              _showLocationSuggestions = false;
            });
          }
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _titleCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            hintText: 'e.g., 12.50',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Amount is required';
                            }
                            return null;
                          },
                        ),
                        if (_isScanningReceipt) ...[
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Scanning receipt...',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationCtrl,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            labelText: 'Location (optional)',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            suffixIcon: _isSearchingLocation
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : (_locationPoint != null
                                    ? const Icon(Icons.check_circle_outline)
                                    : null),
                          ),
                          onChanged: _onLocationChanged,
                          onTap: () {
                            if (_locationSuggestions.isNotEmpty) {
                              setState(() {
                                _showLocationSuggestions = true;
                              });
                            }
                          },
                          onFieldSubmitted: (value) async {
                            await _searchAndSelectLocation(value);
                          },
                        ),
                        _buildLocationSuggestions(scheme),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _searchAndSelectLocation(_locationCtrl.text);
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('Search Location'),
                          ),
                        ),
                        if (_locationError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _locationError!,
                            style: TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (_locationPoint != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 220,
                              width: double.infinity,
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _locationPoint!,
                                  initialZoom: 15,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                    userAgentPackageName: 'com.example.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _locationPoint!,
                                        width: 44,
                                        height: 44,
                                        child: const Icon(
                                          Icons.location_pin,
                                          size: 44,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_scannedRawText != null &&
                            _scannedRawText!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Scanned Text Preview',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.45,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _scannedRawText!,
                              maxLines: 12,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'Category',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
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
                        Text(
                          'Payment',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
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
                        _buildRecurringSection(scheme),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                              _date == null
                                  ? 'Pick date'
                                  : 'Date: ${_date!.toLocal().toString().split(' ').first}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickDueDate,
                            icon: const Icon(Icons.event_available_outlined),
                            label: Text(
                              _dueDate == null
                                  ? 'Pick due date (optional)'
                                  : 'Due Date: ${_dueDate!.toLocal().toString().split(' ').first}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        if (_dueDate != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _dueDate = null);
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Clear due date'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isPaid,
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            setState(() => _isPaid = value ?? false);
                          },
                          title: const Text(
                            'Mark as already paid',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text(
                            'Turn this on if you already settled this expense.',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Add description',
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
                                        labelText: 'Description (optional)',
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
                            label: const Text('Save Expense'),
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
      ),
      floatingActionButton: _isEditing
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isFabOpen) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Import File',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _buildMiniFab(
                        icon: Icons.description_outlined,
                        heroTag: 'file_fab',
                        onPressed: _onFileTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Scan Receipt',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _buildMiniFab(
                        icon: Icons.camera_alt_outlined,
                        heroTag: 'camera_fab',
                        onPressed: _onCameraTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                FloatingActionButton(
                  heroTag: 'main_expandable_fab',
                  onPressed: _toggleFab,
                  child: AnimatedRotation(
                    turns: _isFabOpen ? 0.125 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(_isFabOpen ? Icons.close : Icons.add),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LocationSuggestion {
  final String label;
  final LatLng point;

  const _LocationSuggestion({
    required this.label,
    required this.point,
  });
}