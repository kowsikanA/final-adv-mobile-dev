import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models/expense.dart';

class ChartsPage extends StatelessWidget {
  final List<Expense> expenses;

  const ChartsPage({super.key, required this.expenses});

  Map<String, double> _categoryTotals() {
    final Map<String, double> totals = {};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  Map<String, double> _dailyTotals() {
    final Map<String, double> totals = {};
    for (final e in expenses) {
      if (e.date == null) continue;
      final key = e.date!.toLocal().toString().split(' ').first;
      totals[key] = (totals[key] ?? 0) + e.amount;
    }
    return totals;
  }

  Color _categoryColor(String category, ColorScheme scheme) {
    switch (category.toLowerCase()) {
      case "food":
        return Colors.orange;
      case "transport":
        return Colors.blue;
      case "bills":
        return Colors.redAccent;
      case "shopping":
        return Colors.purple;
      case "entertainment":
        return Colors.teal;
      case "health":
        return Colors.green;
      case "other":
        return Colors.grey;
      default:
        return scheme.primary;
    }
  }

  String _shortCategory(String category) {
    if (category.length <= 8) return category;
    return "${category.substring(0, 8)}…";
  }

  String _shortDate(String fullDate) {
    final parts = fullDate.split('-');
    if (parts.length != 3) return fullDate;
    return "${parts[1]}/${parts[2]}";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final categoryTotals = _categoryTotals();
    final dailyTotals = _dailyTotals();

    final categoryEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final dailyKeys = dailyTotals.keys.toList()..sort();

    final maxCategoryY = categoryEntries.isEmpty
        ? 10.0
        : (categoryEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.25);

    final maxLineY = dailyKeys.isEmpty
        ? 10.0
        : (dailyKeys.map((k) => dailyTotals[k]!).reduce((a, b) => a > b ? a : b) * 1.2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Visual Insights",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "See how your money is distributed across categories and time.",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (expenses.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 54,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No chart data yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Add some expenses to see visualizations.",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // ================= PIE CHART =================
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Spending by Category",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Breakdown of your total spending",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 36,
                        startDegreeOffset: -90,
                        sections: categoryEntries.map((e) {
                          final total = categoryEntries.fold<double>(
                            0,
                            (sum, item) => sum + item.value,
                          );
                          final percent = total == 0 ? 0 : (e.value / total) * 100;

                          return PieChartSectionData(
                            color: _categoryColor(e.key, scheme),
                            value: e.value,
                            title: "${percent.toStringAsFixed(0)}%",
                            radius: 88,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: categoryEntries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _categoryColor(e.key, scheme),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${e.key} • \$${e.value.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ================= BAR CHART =================
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Category Totals",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "How much you spent in each category",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 260,
                    child: BarChart(
                      BarChartData(
                        maxY: maxCategoryY,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: scheme.outlineVariant.withOpacity(0.35),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= categoryEntries.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _shortCategory(categoryEntries[index].key),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: categoryEntries.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: item.value,
                                width: 22,
                                borderRadius: BorderRadius.circular(8),
                                color: _categoryColor(item.key, scheme),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ================= LINE CHART =================
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Spending Over Time",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Track spending trends by date",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 260,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxLineY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: scheme.outlineVariant.withOpacity(0.35),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= dailyKeys.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _shortDate(dailyKeys[index]),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            curveSmoothness: 0.25,
                            color: scheme.primary,
                            barWidth: 4,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: scheme.primary,
                                  strokeWidth: 2,
                                  strokeColor: scheme.surface,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: scheme.primary.withOpacity(0.12),
                            ),
                            spots: List.generate(dailyKeys.length, (index) {
                              return FlSpot(
                                index.toDouble(),
                                dailyTotals[dailyKeys[index]]!,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}