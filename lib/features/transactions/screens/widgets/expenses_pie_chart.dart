import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/models/settings_model.dart';
import '../../../../core/utils/currency_utils.dart';

class ExpensesPieChart extends StatelessWidget {
  final DateTime selectedMonth;
  static const List<Color> _colors = [
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.green,
    Colors.purple,
    Colors.redAccent,
    Colors.teal,
    Colors.brown,
  ];

  const ExpensesPieChart({super.key, required this.selectedMonth});

  Map<String, double> _calculateCategoryTotals(List<TransactionModel> transactions) {
    final filtered = transactions.where((tx) =>
        tx.date.year == selectedMonth.year &&
        tx.date.month == selectedMonth.month);

    final totals = <String, double>{};
    for (var tx in filtered) {
      if (tx.isExpense) { // Use isExpense field
        // Amount is already positive for expenses if isExpense is true
        totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
      }
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<TransactionModel>('transactions').listenable(),
      builder: (context, Box<TransactionModel> box, _) {
        final transactions = box.values.toList();
        final categoryTotals = _calculateCategoryTotals(transactions);
        final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

        return ValueListenableBuilder(
          valueListenable: Hive.box<SettingsModel>('settings').listenable(),
          builder: (context, Box<SettingsModel> settingsBox, _) {
            final settings = settingsBox.get('user')!;
            final currencySymbol = getCurrencySymbol(settings.currency);

            if (total == 0) {
              return const Center(
                child: Text(
                  'No hay gastos para mostrar en este mes',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return PieChart(
              PieChartData(
                sections: categoryTotals.entries.toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final category = entry.value.key;
                  final amount = entry.value.value;
                  final percentage = (amount / total * 100).toStringAsFixed(1);

                  return PieChartSectionData(
                    color: _colors[i % _colors.length],
                    value: amount,
                    title: '$category\n$currencySymbol${amount.toStringAsFixed(0)}\n$percentage%',
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    titlePositionPercentageOffset: 0.6,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                startDegreeOffset: 180,
              ),
              swapAnimationDuration: const Duration(milliseconds: 500), // Reducido de 800ms
              swapAnimationCurve: Curves.easeInOut,
            );
          },
        );
      },
    );
  }
}
