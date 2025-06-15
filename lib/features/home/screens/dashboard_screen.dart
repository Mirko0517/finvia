import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finvia_flutter/widgets/animated_card.dart'; // Corrected import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../data/models/settings_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../features/transactions/screens/new_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Widget buildHeader(SettingsModel settings) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blueGrey.shade200,
          child: const Icon(Icons.person_outline, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${settings.username.isNotEmpty ? settings.username : "usuario"} 👋',
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Bienvenido a Finvia',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Hive.box<SettingsModel>('settings').get('user')!;
    final symbol = getCurrencySymbol(settings.currency);
    final now = DateTime.now();
    final box = Hive.box<TransactionModel>('transactions');
    final monthTx = box.values.where((tx) =>
      tx.date.year == now.year && tx.date.month == now.month).toList();

    // Updated financial logic using isExpense
    final income = monthTx.where((tx) => !tx.isExpense).fold(0.0, (s, tx) => s + tx.amount);
    final expenses = monthTx.where((tx) => tx.isExpense).fold(0.0, (s, tx) => s + tx.amount);
    // Balance: salary + all income transactions - all expense transactions
    final balance = settings.monthlySalary + income - expenses;

    final lastTx = box.values.toList().reversed.take(5).toList();

    // Calcular estadísticas por categoría (solo gastos)
    final categoryStats = <String, double>{};
    for (var tx in monthTx.where((tx) => tx.isExpense)) { // Filter by isExpense = true
      categoryStats[tx.category] = (categoryStats[tx.category] ?? 0) + tx.amount; // Amount is already positive
    }

    // Encontrar la categoría con más gastos
    String topCategory = 'Sin gastos';
    double topAmount = 0;
    if (categoryStats.isNotEmpty) {
      topCategory = categoryStats.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      topAmount = categoryStats[topCategory] ?? 0;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(settings),
              const SizedBox(height: 24),

              // Card: Balance mensual
              AnimatedCard(child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Balance mensual',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                            color: Colors.blueGrey[300], size: 20),
                          const SizedBox(width: 8),
                          Text('Sueldo base: ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Expanded(
                            child: Text(
                              '$symbol${settings.monthlySalary.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.arrow_upward_outlined,
                            color: Colors.teal[300], size: 20),
                          const SizedBox(width: 8),
                          Text('Ingresos extra: ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Expanded(
                            child: Text(
                              '$symbol${income.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[700],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.arrow_downward_outlined,
                            color: Colors.red[300], size: 20),
                          const SizedBox(width: 8),
                          Text('Gastos: ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Expanded(
                            child: Text(
                              // expenses is now sum of positive numbers
                              '$symbol${expenses.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      Row(
                        children: [
                          Text('Balance total: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$symbol${balance.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: balance >= 0 ? Colors.green[700] : Colors.red[700],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 24),

              // Stats Grid
              Text(
                'Resumen del mes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Mayor gasto',
                    '$symbol${topAmount.toStringAsFixed(0)}',
                    Icons.category_outlined,
                    Colors.purple.shade300,
                  ),
                  _buildStatCard(
                    'Categoría',
                    topCategory,
                    Icons.label_outlined,
                    Colors.teal.shade300,
                  ),
                  _buildStatCard(
                    'Total gastos',
                    // expenses is now sum of positive numbers
                    '$symbol${expenses.toStringAsFixed(0)}',
                    Icons.trending_down,
                    Colors.red.shade300,
                  ),
                  _buildStatCard(
                    'Total ingresos',
                    // income is only extra income, salary is base
                    '$symbol${(income + settings.monthlySalary).toStringAsFixed(0)}',
                    Icons.trending_up,
                    Colors.green.shade300,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Card: Últimas transacciones
              AnimatedCard(child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Últimas transacciones',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Text(
                            'Ver todas',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (lastTx.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No hay transacciones aún.'),
                          ),
                        )
                      else
                        ...lastTx.map((tx) => Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[100],
                                child: Icon(
                                  !tx.isExpense ? Icons.add : Icons.remove, // Use isExpense
                                  color: !tx.isExpense ? Colors.teal[300] : Colors.red[300], // Use isExpense
                                ),
                              ),
                              title: Text(tx.title),
                              subtitle: Text(tx.category),
                              trailing: Text(
                                // Amount is already correctly signed for display if needed,
                                // but usually we show absolute for list items and color indicates type.
                                // Here, the amount should be positive for both, color indicates type.
                                '$symbol${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !tx.isExpense ? Colors.teal[700] : Colors.red[700], // Use isExpense
                                ),
                              ),
                            ),
                            if (lastTx.last != tx) const Divider(),
                          ],
                        )).toList(),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewTransactionScreen()),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Nueva transacción",
          style: GoogleFonts.openSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
