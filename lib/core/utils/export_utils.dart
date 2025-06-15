import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/transaction_model.dart';

Future<String> exportTransactionsAsCSV() async {
  final box = Hive.box<TransactionModel>('transactions');
  final transactions = box.values.toList();

  List<List<String>> csvData = [
    ['Título', 'Categoría', 'Monto', 'Fecha']
  ];

  for (var tx in transactions) {
    csvData.add([
      tx.title,
      tx.category,
      tx.amount.toStringAsFixed(2),
      tx.date
          .toLocal()
          .toString()
          .split(' ')[0] // Formato más amigable de fecha
    ]);
  }

  String csv = const ListToCsvConverter().convert(csvData);

  final dir = await getApplicationDocumentsDirectory();
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final file = File('${dir.path}/finvia_export_$timestamp.csv');
  await file.writeAsString(csv);

  return file.path;
}

Future<String> exportTransactionsAsJSON() async {
  final box = Hive.box<TransactionModel>('transactions');
  final transactions = box.values
      .map((tx) => {
            'title': tx.title,
            'category': tx.category,
            'amount': tx.amount.toStringAsFixed(2),
            'date': tx.date
                .toLocal()
                .toString()
                .split(' ')[0], // Formato más amigable de fecha
          })
      .toList();

  final jsonData = const JsonEncoder.withIndent('  ').convert(transactions);

  final dir = await getApplicationDocumentsDirectory();
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final file = File('${dir.path}/finvia_export_$timestamp.json');
  await file.writeAsString(jsonData);

  return file.path;
}
