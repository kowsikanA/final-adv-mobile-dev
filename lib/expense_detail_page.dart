import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'add_expense.dart';
import 'database/expense_database.dart';
import 'models/expense.dart';
import 'stripe_service.dart';

class ExpenseDetailPage extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailPage({
    super.key,
    required this.expense,
  });

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  final MapController _mapController = MapController();

  LatLng? _locationPoint;
  bool _isLoadingLocation = false;
  String? _locationError;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final locationText = widget.expense.location;

    if (locationText == null || locationText.trim().isEmpty) return;

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final results = await locationFromAddress(locationText);

      if (results.isNotEmpty) {
        final first = results.first;
        final point = LatLng(first.latitude, first.longitude);

        if (!mounted) return;
        setState(() {
          _locationPoint = point;
          _isLoadingLocation = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(point, 15);
        });
      } else {
        if (!mounted) return;
        setState(() {
          _locationError = "Location not found";
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = "Could not load map for this location";
        _isLoadingLocation = false;
      });
    }
  }

  String _money(double value) => "\$${value.toStringAsFixed(2)}";

  String _formatDate(DateTime? date) {
    if (date == null) return "No date";
    return date.toLocal().toString().split(' ').first;
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return "No due date";
    return date.toLocal().toString().split(' ').first;
  }

  bool get _isOverdue {
    final dueDate = widget.expense.dueDate;
    if (dueDate == null || widget.expense.isPaid) return false;
    final today = DateTime.now();
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final now = DateTime(today.year, today.month, today.day);
    return due.isBefore(now);
  }

  Future<void> _markAsPaid() async {
    if (widget.expense.id == null) return;

    await ExpenseDatabase.instance.updateExpense(
      widget.expense.copyWith(isPaid: true),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense marked as paid')),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _payWithStripe() async {
    if (_isPaying || widget.expense.isPaid) return;

    setState(() {
      _isPaying = true;
    });

    try {
      await StripeService.pay(
        amount: widget.expense.amount,
        title: widget.expense.title,
      );

      if (!mounted) return;

      await ExpenseDatabase.instance.updateExpense(
        widget.expense.copyWith(isPaid: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stripe payment successful')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isPaying = false;
      });
    }
  }

  Widget _buildStatusChip(ColorScheme scheme) {
    final isPaid = widget.expense.isPaid;
    final label = isPaid
        ? 'Paid'
        : _isOverdue
            ? 'Overdue'
            : 'Unpaid';
    final color = isPaid
        ? Colors.green
        : _isOverdue
            ? scheme.error
            : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _openEditor({required bool duplicate}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddExpensePage(
          initialExpense: widget.expense,
          duplicateMode: duplicate,
        ),
      ),
    );

    if (!mounted) return;
    if (changed == true) {
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final scheme = Theme.of(context).colorScheme;
    final heroTag = 'expense-card-${expense.id}';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            actions: [
              IconButton(
                tooltip: 'Duplicate expense',
                onPressed: () => _openEditor(duplicate: true),
                icon: const Icon(Icons.copy_all_outlined),
              ),
              IconButton(
                tooltip: 'Edit expense',
                onPressed: () => _openEditor(duplicate: false),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Center(
                child: Hero(
                  tag: heroTag,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 220,
                      height: 140,
                      margin: const EdgeInsets.only(top: 40),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            expense.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _money(expense.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    context: context,
                    icon: Icons.title,
                    label: "Title",
                    value: expense.title,
                    color: scheme.primary,
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.attach_money,
                    label: "Amount",
                    value: _money(expense.amount),
                    color: scheme.primary,
                  ),
                  Row(
                    children: [
                      _buildStatusChip(scheme),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.category_outlined,
                    label: "Category",
                    value: expense.category,
                    color: scheme.primary,
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.calendar_month_outlined,
                    label: "Date",
                    value: _formatDate(expense.date),
                    color: scheme.primary,
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.event_available_outlined,
                    label: "Due Date",
                    value: _formatDueDate(expense.dueDate),
                    color: _isOverdue ? scheme.error : scheme.primary,
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.credit_card_outlined,
                    label: "Payment Method",
                    value: expense.paymentMethod,
                    color: scheme.primary,
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.notes_outlined,
                    label: "Description",
                    value: (expense.description == null ||
                            expense.description!.trim().isEmpty)
                        ? "No description"
                        : expense.description!,
                    color: scheme.primary,
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.location_on_outlined,
                    label: "Location",
                    value: (expense.location == null ||
                            expense.location!.trim().isEmpty)
                        ? "No location"
                        : expense.location!,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: expense.isPaid ? null : _markAsPaid,
                      icon: Icon(
                        expense.isPaid
                            ? Icons.check_circle
                            : Icons.payment_outlined,
                      ),
                      label: Text(
                        expense.isPaid ? "Already Paid" : "Mark as Paid",
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: expense.isPaid || _isPaying ? null : _payWithStripe,
                      icon: _isPaying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.credit_card_outlined),
                      label: Text(_isPaying ? "Processing..." : "Pay with Stripe"),
                    ),
                  ),
                  if (_isLoadingLocation) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_locationError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _locationError!,
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_locationPoint != null) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 240,
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
                                    color: Colors.red,
                                    size: 44,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}