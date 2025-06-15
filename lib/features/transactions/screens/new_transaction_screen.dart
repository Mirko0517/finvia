import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../data/models/transaction_model.dart';

class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'General';

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    // Get the amount and ensure it's positive
    final double amount = double.parse(_amountController.text).abs();

    // Determine if it's an expense
    final bool isExpense = _selectedCategory != 'Ingreso';

    final box = Hive.box<TransactionModel>('transactions');
    final newTx = TransactionModel(
      id: box.length + 1, // Consider a more robust ID generation for production apps
      title: _titleController.text,
      amount: amount, // Store positive amount
      date: _selectedDate,
      category: _selectedCategory,
      isExpense: isExpense, // Set the isExpense flag
      // description field is optional and will default to null
    );

    box.add(newTx);
    Navigator.of(context).pop(); // cerrar pantalla
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva transacción'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalles',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Título',
                              prefixIcon: Icon(Icons.edit_note_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Monto',
                              prefixIcon: Icon(Icons.attach_money_outlined),
                            ),
                            validator: (value) =>
                                value == null || double.tryParse(value) == null
                                    ? 'Ingresa un número válido'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categoría y Fecha',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            items: ['Ingreso', 'General', 'Alimentos', 'Transporte', 'Salud', 'Ocio']
                                .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Row(
                                    children: [
                                      Icon(
                                        cat == 'Ingreso' ? Icons.add_circle_outline :
                                        cat == 'Alimentos' ? Icons.restaurant_outlined :
                                        cat == 'Transporte' ? Icons.directions_car_outlined :
                                        cat == 'Salud' ? Icons.medical_services_outlined :
                                        cat == 'Ocio' ? Icons.sports_esports_outlined :
                                        Icons.category_outlined,
                                        color: cat == 'Ingreso'
                                          ? Colors.teal[300]
                                          : Colors.white70,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(cat),
                                    ],
                                  ),
                                ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).inputDecorationTheme.fillColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveTransaction,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('GUARDAR TRANSACCIÓN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
