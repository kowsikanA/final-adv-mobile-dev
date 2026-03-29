import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'database/expense_database.dart';
import 'models/expense.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

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

  void _onCameraTap() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Camera action tapped")),
    );
  }

  void _onFileTap() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("XLSX/File action tapped")),
    );
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
          // keep fallback lat/lng label
        }

        suggestions.add(
          _LocationSuggestion(
            label: label,
            latitude: loc.latitude,
            longitude: loc.longitude,
          ),
        );
      }

      // remove duplicate labels
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
      _mapController.move(point, 15);
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
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
    );

    await ExpenseDatabase.instance.insertExpense(expense);

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
      floatingActionButton: Column(
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