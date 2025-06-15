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
    // Use _selectedMonth instead of DateTime.now()
    final monthTransactions = transactions.where((tx) =>
      tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month
    ).toList();

    // Updated logic using isExpense (amounts are positive for expenses in model)
    final expenses = monthTransactions
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    // extraIncome are transactions that are not expenses
    final extraIncome = monthTransactions
        .where((tx) => !tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return {
      'expenses': expenses, // This is now a sum of positive amounts
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
                    // Corrected balance calculation: expenses are already positive
                    final balance = settings.monthlySalary +
                        monthlyStats['extraIncome']! -
                        monthlyStats['expenses']!;

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
                                      !tx.isExpense ? Icons.add : Icons.remove, // Use isExpense
                                      color: !tx.isExpense
                                        ? Colors.teal[300]
                                        : Colors.red[300], // Use isExpense
                                    ),
                                  ),
                                  title: Text(tx.title),
                                  subtitle: Text(
                                    '${tx.category} • ${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  trailing: Text(
                                    // Amount is positive for both, color indicates type
                                    '$currencySymbol${tx.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !tx.isExpense
                                        ? Colors.teal[300]
                                        : Colors.red[300], // Use isExpense
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
