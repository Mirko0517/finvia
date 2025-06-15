import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/transaction_model.dart';

// Helper function to get transactions in a common format
Future<List<Map<String, dynamic>>?> _getTransactionsForExport() async {
  try {
    final box = Hive.box<TransactionModel>('transactions');
    final transactions = box.values.toList();

    return transactions.map((tx) {
      return {
        'title': tx.title,
        'category': tx.category,
        'amount': tx.amount.toStringAsFixed(2),
        'date': tx.date.toLocal().toString().split(' ')[0],
        // Add other fields if necessary, ensuring consistency
        'description': tx.description,
        'isExpense': tx.isExpense,
      };
    }).toList();
  } on HiveError catch (e) {
    debugPrint('HiveError while fetching transactions for export: $e');
    return null;
  } catch (e) {
    debugPrint('Error fetching transactions for export: $e');
    return null;
  }
}

// Helper function to get the export file path
Future<File?> _getExportFilePath(String extension) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    // Sanitize the timestamp to be a valid filename component
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final fileName = 'finvia_export_$timestamp.$extension';
    return File('${dir.path}/$fileName');
  } catch (e) {
    debugPrint('Error getting export file path: $e');
    return null;
  }
}

Future<String?> exportTransactionsAsCSV() async {
  try {
    final transactions = await _getTransactionsForExport();
    if (transactions == null) {
      return null; // Error already logged by helper
    }

    List<List<String>> csvData = [
      // Define headers based on the structure from _getTransactionsForExport
      ['Título', 'Categoría', 'Monto', 'Fecha', 'Descripción', 'Es Gasto']
    ];

    for (var txMap in transactions) {
      csvData.add([
        txMap['title'] ?? '',
        txMap['category'] ?? '',
        txMap['amount'] ?? '0.00',
        txMap['date'] ?? '',
        txMap['description'] ?? '',
        (txMap['isExpense'] ?? false).toString(),
      ]);
    }

    String csvString = const ListToCsvConverter().convert(csvData);
    final file = await _getExportFilePath('csv');
    if (file == null) {
      return null; // Error already logged by helper
    }

    await file.writeAsString(csvString);
    debugPrint('Exported to CSV: ${file.path}');
    return file.path;
  } on FileSystemException catch (e) {
    debugPrint('FileSystemException during CSV export: $e');
    return null;
  } catch (e) {
    debugPrint('Error exporting transactions as CSV: $e');
    return null;
  }
}

Future<String?> exportTransactionsAsJSON() async {
  try {
    final transactions = await _getTransactionsForExport();
    if (transactions == null) {
      return null; // Error already logged by helper
    }

    final jsonData = const JsonEncoder.withIndent('  ').convert(transactions);
    final file = await _getExportFilePath('json');
    if (file == null) {
      return null; // Error already logged by helper
    }

    await file.writeAsString(jsonData);
    debugPrint('Exported to JSON: ${file.path}');
    return file.path;
  } on FileSystemException catch (e) {
    debugPrint('FileSystemException during JSON export: $e');
    return null;
  } catch (e) {
    debugPrint('Error exporting transactions as JSON: $e');
    return null;
  }
}
