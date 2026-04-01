import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
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

  bool _isFabOpen = false;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  final MapController _mapController = MapController();
  LatLng? _locationPoint;
  bool _isSearchingLocation = false;
  String? _locationError;

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

    final initial = widget.initialExpense;
    if (initial != null) {
      _titleCtrl.text = initial.title;
      _amountCtrl.text = initial.amount.toStringAsFixed(2);
      _descCtrl.text = initial.description ?? '';
      _locationCtrl.text = initial.location ?? '';
      _date = initial.date ?? DateTime.now();
      _selectedCategory = _categories.contains(initial.category)
          ? initial.category
          : 'Other';
      _selectedPayment = _paymentMethods.contains(initial.paymentMethod)
          ? initial.paymentMethod
          : 'Cash';
      _showDescription = _descCtrl.text.trim().isNotEmpty;

      if ((initial.location ?? '').trim().isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final suggestions = await _fetchLocationSuggestions(initial.location!);
          if (suggestions.isNotEmpty && mounted) {
            await _selectLocation(suggestions.first);
          }
        });
      }
    }
  }

  @override
  void dispose() {
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

  Future<void> _onCameraTap() async {
    HapticFeedback.lightImpact();

    setState(() {
      _isFabOpen = false;
    });
    _fabController.reverse();

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (!mounted) return;
      setState(() {
        _isScanningReceipt = true;
      });

      final inputImage = InputImage.fromFilePath(pickedFile.path);

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final extractedText = recognizedText.text;
      _scannedRawText = extractedText;

      if (_descCtrl.text.trim().isEmpty && extractedText.trim().isNotEmpty) {
        _descCtrl.text = extractedText;
        _showDescription = true;
      }

      await _extractExpenseFieldsFromText(extractedText);

      HapticFeedback.mediumImpact();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receipt scanned successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Scan failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanningReceipt = false;
        });
      }
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

      if (result == null || result.files.isEmpty) {
        return;
      }

      final picked = result.files.single;
      final path = picked.path;
      if (path == null) {
        throw Exception("Unable to read selected file path.");
      }

      final extension = (picked.extension ?? '').toLowerCase();
      final file = File(path);

      List<Map<String, dynamic>> rows = [];

      if (extension == 'csv') {
        final input = await file.readAsString();
        final csvTable = CsvToListConverter().convert(input);

        if (csvTable.isEmpty) {
          throw Exception("CSV file is empty.");
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
          throw Exception("Excel file has no sheets.");
        }

        final sheet = excel.tables.values.first;
        if (sheet.rows.isEmpty) {
          throw Exception("Excel sheet is empty.");
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
        throw Exception("Unsupported file type.");
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
            'total'
          ]),
        );

        if (amount == null || amount <= 0) continue;

        final parsedDate = _parseDate(
          _readAny(row, const ['date', 'expense date', 'day']),
        );

        final description =
            _stringValue(_readAny(row, const ['description', 'details', 'note']));

        final title = _stringValue(
              _readAny(row, const ['title', 'name', 'item']),
            ) ??
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
            category: _normalizeCategory(categoryText) ??
                _inferCategoryFromReceipt(combinedText),
            date: parsedDate ?? DateTime.now(),
            description: description,
            paymentMethod: _normalizePaymentMethod(paymentText) ?? "Cash",
            location: locationText,
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
                ? "Imported $importedCount expense(s)"
                : "No valid expense rows found in file",
          ),
        ),
      );

      if (importedCount > 0) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Import failed: $e")),
      );
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
    final joined = row.values.map((e) => e?.toString().toLowerCase() ?? '').join(' ');
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

  bool _looksLikeNonTitleLine(String line) {
    final lower = line.toLowerCase();

    return lower.contains('receipt') ||
        lower.contains('sales receipt') ||
        lower.contains('invoice') ||
        lower.contains('approval #') ||
        lower.contains('transaction #') ||
        lower.contains('account #') ||
        lower.contains('paid by') ||
        lower.contains('table') ||
        lower.contains('tisch') ||
        lower.contains('total') ||
        lower.contains('subtotal') ||
        lower.contains('tax') ||
        lower.contains('mwst') ||
        lower.contains('tel') ||
        lower.contains('fax') ||
        lower.contains('email') ||
        RegExp(r'^\d[\d/\-:. ]+$').hasMatch(lower);
  }

  String? _extractBestTitleFromReceipt(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final line in lines.take(6)) {
      if (_looksLikeNonTitleLine(line)) continue;
      if (line.length < 3) continue;

      final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
      final digits = RegExp(r'\d').allMatches(line).length;

      if (letters >= 3 && letters >= digits) {
        return line.length > 40 ? line.substring(0, 40) : line;
      }
    }

    return lines.isNotEmpty ? lines.first : null;
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

    final totalLineRegex = RegExp(
      r'(total|grand total|amount due|balance due|gesamt|summe)',
      caseSensitive: false,
    );

    final amountRegex = RegExp(
      r'(?<!\d)(\d{1,4}[.,]\d{2})(?!\d)',
    );

    for (final line in lines) {
      if (totalLineRegex.hasMatch(line)) {
        final matches = amountRegex.allMatches(line).toList();
        if (matches.isNotEmpty) {
          final last = matches.last.group(0);
          final parsed = _tryParseReceiptAmount(last ?? '');
          if (parsed != null && parsed > 0) {
            return parsed;
          }
        }
      }
    }

    final currencyLineRegex = RegExp(
      r'(CHF|EUR|USD|CAD|\$)',
      caseSensitive: false,
    );

    final currencyCandidates = <double>[];

    for (final line in lines) {
      if (currencyLineRegex.hasMatch(line)) {
        final matches = amountRegex.allMatches(line);
        for (final m in matches) {
          final parsed = _tryParseReceiptAmount(m.group(0) ?? '');
          if (parsed != null && parsed > 0) {
            currencyCandidates.add(parsed);
          }
        }
      }
    }

    if (currencyCandidates.isNotEmpty) {
      return currencyCandidates.reduce((a, b) => a > b ? a : b);
    }

    final blockedLineRegex = RegExp(
      r'(rech|invoice|table|tisch|tel|fax|mwst|vat|nr|no\.)',
      caseSensitive: false,
    );

    final fallbackCandidates = <double>[];

    for (final line in lines) {
      if (blockedLineRegex.hasMatch(line)) continue;

      final matches = amountRegex.allMatches(line);
      for (final m in matches) {
        final parsed = _tryParseReceiptAmount(m.group(0) ?? '');
        if (parsed != null && parsed > 0) {
          fallbackCandidates.add(parsed);
        }
      }
    }

    if (fallbackCandidates.isNotEmpty) {
      return fallbackCandidates.reduce((a, b) => a > b ? a : b);
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
          lower.contains('gurnee') ||
          lower.contains('grindelwald') ||
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
        lower.contains('schnitzel') ||
        lower.contains('supermarket') ||
        lower.contains('grocery') ||
        lower.contains('eggplant') ||
        lower.contains('onion') ||
        lower.contains('mango') ||
        lower.contains('pumpkin')) {
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

  Future<void> _extractExpenseFieldsFromText(String text) async {
    if (text.trim().isEmpty) return;

    final normalizedText = _normalizeReceiptText(text);

    if (_titleCtrl.text.trim().isEmpty) {
      final bestTitle = _extractBestTitleFromReceipt(normalizedText);
      if (bestTitle != null && bestTitle.trim().isNotEmpty) {
        _titleCtrl.text = bestTitle;
      }
    }

    if (_amountCtrl.text.trim().isEmpty) {
      final bestAmount = _extractBestAmountFromReceipt(normalizedText);
      if (bestAmount != null) {
        _amountCtrl.text = bestAmount.toStringAsFixed(2);
      }
    }

    DateTime? bestDate;

    try {
      final extractor = EntityExtractor(
        language: EntityExtractorLanguage.english,
      );

      final annotations = await extractor.annotateText(normalizedText);

      String? moneyEntityText;
      String? addressEntityText;

      for (final annotation in annotations) {
        for (final entity in annotation.entities) {
          switch (entity.type) {
            case EntityType.money:
              moneyEntityText ??= annotation.text;
              break;
            case EntityType.address:
              addressEntityText ??= annotation.text;
              break;
            case EntityType.dateTime:
              final parsed = _parseDate(annotation.text);
              if (parsed != null) {
                bestDate = parsed;
              }
              break;
            default:
              break;
          }
        }

        if (bestDate != null) {
          break;
        }
      }

      if (_amountCtrl.text.trim().isEmpty && moneyEntityText != null) {
        final parsed = _tryParseReceiptAmount(moneyEntityText);
        if (parsed != null && parsed > 0) {
          _amountCtrl.text = parsed.toStringAsFixed(2);
        }
      }

      if (_locationCtrl.text.trim().isEmpty &&
          addressEntityText != null &&
          addressEntityText.trim().isNotEmpty) {
        _locationCtrl.text = addressEntityText.trim();
      }

      await extractor.close();
    } catch (_) {
      // ignore extraction failures
    }

    bestDate ??= _extractBestDateFromReceipt(normalizedText);

    if (bestDate != null) {
      _date = bestDate;
    }

    if (_descCtrl.text.trim().isEmpty && normalizedText.trim().isNotEmpty) {
      _descCtrl.text = normalizedText.trim();
      _showDescription = true;
    }

    if (_locationCtrl.text.trim().isEmpty) {
      final bestLocation = _extractBestLocationFromReceipt(normalizedText);
      if (bestLocation != null && bestLocation.trim().isNotEmpty) {
        _locationCtrl.text = bestLocation;
      }
    }

    if (_selectedCategory == "Food" || _selectedCategory == "Other") {
      _selectedCategory = _inferCategoryFromReceipt(normalizedText);
    }

    if (_locationCtrl.text.trim().isNotEmpty) {
      final suggestions = await _fetchLocationSuggestions(_locationCtrl.text);
      if (suggestions.isNotEmpty && mounted) {
        await _selectLocation(suggestions.first);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<List<_LocationSuggestion>> _fetchLocationSuggestions(
    String pattern,
  ) async {
    final query = pattern.trim();
    if (query.length < 3) return [];

    try {
      final results = await locationFromAddress(query);
      final suggestions = <_LocationSuggestion>[];

      for (final loc in results.take(5)) {
        String label =
            "${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}";

        try {
          final placemarks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = <String>[
              if ((p.name ?? "").trim().isNotEmpty) p.name!.trim(),
              if ((p.locality ?? "").trim().isNotEmpty) p.locality!.trim(),
              if ((p.administrativeArea ?? "").trim().isNotEmpty)
                p.administrativeArea!.trim(),
              if ((p.country ?? "").trim().isNotEmpty) p.country!.trim(),
            ];
            if (parts.isNotEmpty) {
              label = parts.join(", ");
            }
          }
        } catch (_) {
          // keep fallback label
        }

        suggestions.add(
          _LocationSuggestion(
            label: label,
            latitude: loc.latitude,
            longitude: loc.longitude,
          ),
        );
      }

      final seen = <String>{};
      return suggestions.where((s) => seen.add(s.label)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _selectLocation(_LocationSuggestion suggestion) async {
    HapticFeedback.selectionClick();

    final point = LatLng(suggestion.latitude, suggestion.longitude);

    setState(() {
      _locationCtrl.text = suggestion.label;
      _locationPoint = point;
      _locationError = null;
      _isSearchingLocation = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(point, 15);
      } catch (_) {}
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amount must be greater than 0")),
      );
      return;
    }

    final expense = Expense(
      id: _isEditing ? widget.initialExpense!.id : null,
      title: _titleCtrl.text.trim(),
      amount: amount,
      category: _selectedCategory,
      date: _date,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      paymentMethod: _selectedPayment,
      location:
          _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
    );

    if (_isEditing) {
      await ExpenseDatabase.instance.updateExpense(expense);
    } else {
      await ExpenseDatabase.instance.insertExpense(expense);
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
                          if (v == null || v.trim().isEmpty) {
                            return "Title is required";
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
                          labelText: "Amount",
                          hintText: "e.g., 12.50",
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Amount is required";
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
                              "Scanning receipt...",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      TypeAheadField<_LocationSuggestion>(
                        suggestionsCallback: (pattern) async {
                          setState(() {
                            _isSearchingLocation = true;
                            _locationError = null;
                          });

                          final items = await _fetchLocationSuggestions(pattern);

                          if (mounted) {
                            setState(() {
                              _isSearchingLocation = false;
                              if (pattern.trim().length >= 3 && items.isEmpty) {
                                _locationError = "No matching locations found";
                              } else {
                                _locationError = null;
                              }
                            });
                          }

                          return items;
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(
                              suggestion.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                        onSelected: _selectLocation,
                        builder: (context, controller, focusNode) {
                          if (controller.text != _locationCtrl.text) {
                            controller.text = _locationCtrl.text;
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          }

                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: "Location (optional)",
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
                            onChanged: (value) {
                              _locationCtrl.text = value;
                              if (value.trim().isEmpty) {
                                setState(() {
                                  _locationPoint = null;
                                  _locationError = null;
                                });
                              }
                            },
                          );
                        },
                        emptyBuilder: (context) => const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text("No matching locations"),
                        ),
                        loadingBuilder: (context) => const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      if (_locationError != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _locationError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (_locationPoint != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 220,
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Scanned Text Preview",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                scheme.surfaceContainerHighest.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _scannedRawText!,
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
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
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          "Import File",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _buildMiniFab(
                        icon: Icons.description_outlined,
                        heroTag: "file_fab",
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
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          "Scan Receipt",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _buildMiniFab(
                        icon: Icons.camera_alt_outlined,
                        heroTag: "camera_fab",
                        onPressed: _onCameraTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                FloatingActionButton(
                  heroTag: "main_expandable_fab",
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
  final double latitude;
  final double longitude;

  const _LocationSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}