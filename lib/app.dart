import 'package:flutter/material.dart';
import 'package:finvia_flutter/core/theme/app_theme.dart';
import 'package:finvia_flutter/features/main/screens/main_screen.dart';
import 'package:finvia_flutter/features/transactions/screens/new_transaction_screen.dart';

class FinviaApp extends StatelessWidget {
  const FinviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finvia',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
      routes: {
        '/add': (context) => const NewTransactionScreen(),
      },
    );
  }
}
