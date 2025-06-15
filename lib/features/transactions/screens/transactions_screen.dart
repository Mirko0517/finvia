import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/settings_model.dart';
import '../../../core/utils/currency_utils.dart';
import 'new_transaction_screen.dart';
import '../../../features/settings/screens/settings_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _selectedCategory;
  DateTime _selectedMonth = DateTime.now();
  late final Box<TransactionModel> _transactionsBox;
  late final Box<SettingsModel> _settingsBox;

  final List<String> _categories = [
    'Todas',
    'General',
    'Alimentos',
    'Transporte',
    'Salud',
    'Ocio'
  ];

  @override
  void initState() {
    super.initState();
    _transactionsBox = Hive.box<TransactionModel>('transactions');
    _settingsBox = Hive.box<SettingsModel>('settings');
  }

  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> transactions) {
    return transactions.where((tx) {
      final sameMonth = tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
      final categoryMatch = _selectedCategory == null ||
          _selectedCategory == 'Todas' ||
          tx.category == _selectedCategory;
      return sameMonth && categoryMatch;
    }).toList();
  }

  Map<String, double> _calculateMonthlyStats(List<TransactionModel> transactions) {
    final now = DateTime.now();

    final monthTransactions = transactions.where((tx) =>
      tx.date.year == now.year && tx.date.month == now.month
    ).toList();

    // Corregimos el cálculo de gastos (montos negativos)
    final expenses = monthTransactions
        .where((tx) => tx.amount <= 0) // Cambiamos a <= para incluir transacciones de 0
        .fold(0.0, (sum, tx) => sum - tx.amount); // Cambiamos el signo aquí

    // Solo los montos positivos son ingresos extra
    final extraIncome = monthTransactions
        .where((tx) => tx.amount > 0)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return {
      'expenses': expenses,
      'extraIncome': extraIncome,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        actions: [
          IconButton(
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Seleccionar mes',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    border: InputBorder.none,
                    labelText: 'Filtrar por categoría',
                  ),
                  value: _selectedCategory ?? 'Todas',
                  items: _categories.map((cat) =>
                    DropdownMenuItem(value: cat, child: Text(cat))
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedCategory = value);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _transactionsBox.listenable(),
              builder: (context, Box<TransactionModel> box, _) {
                final allTransactions = box.values.toList();
                final filtered = _getFilteredTransactions(allTransactions);
                final monthlyStats = _calculateMonthlyStats(allTransactions);

                return ValueListenableBuilder(
                  valueListenable: _settingsBox.listenable(),
                  builder: (context, Box<SettingsModel> settingsBox, _) {
                    final settings = settingsBox.get('user')!;
                    final currencySymbol = getCurrencySymbol(settings.currency);
                    final balance = settings.monthlySalary +
                        monthlyStats['extraIncome']! -
                        monthlyStats['expenses']!.abs();

                    return filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay transacciones para este filtro',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final tx = filtered[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    child: Icon(
                                      tx.amount > 0 ? Icons.add : Icons.remove,
                                      color: tx.amount > 0
                                        ? Colors.teal[300]
                                        : Colors.red[300],
                                    ),
                                  ),
                                  title: Text(tx.title),
                                  subtitle: Text(
                                    '${tx.category} • ${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  trailing: Text(
                                    '$currencySymbol${tx.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tx.amount > 0
                                        ? Colors.teal[300]
                                        : Colors.red[300],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewTransactionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva transacción'),
      ),
    );
  }
}
