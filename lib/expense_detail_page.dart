import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'models/expense.dart';

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
              color: color.withOpacity(0.12),
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
                        color: Colors.white.withOpacity(0.18),
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
                    icon: Icons.credit_card_outlined,
                    label: "Payment Method",
                    value: expense.paymentMethod,
                    color: scheme.primary,
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.notes_outlined,
                    label: "Description",
                    value: (expense.description == null || expense.description!.trim().isEmpty)
                        ? "No description"
                        : expense.description!,
                    color: scheme.primary,
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.location_on_outlined,
                    label: "Location",
                    value: (expense.location == null || expense.location!.trim().isEmpty)
                        ? "No location"
                        : expense.location!,
                    color: scheme.primary,
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