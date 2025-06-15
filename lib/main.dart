import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/transaction_model.dart';
import 'data/models/settings_model.dart';
import 'features/main/screens/main_screen.dart';
import 'features/transactions/screens/new_transaction_screen.dart';
import 'package:google_fonts/google_fonts.dart';

final _darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF6C63FF),
  brightness: Brightness.dark,
  surface: const Color(0xFF1E1E1E),
  background: const Color(0xFF121212),
  primary: const Color(0xFF6C63FF),
  secondary: const Color(0xFF9089FF),
);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _darkColorScheme,
  scaffoldBackgroundColor: const Color(0xFF121212),
  cardColor: const Color(0xFF1E1E1E),
  textTheme: GoogleFonts.openSansTextTheme(ThemeData.dark().textTheme).copyWith(
    titleLarge: GoogleFonts.openSans(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleMedium: GoogleFonts.openSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodyLarge: GoogleFonts.openSans(
      fontSize: 16,
      color: Colors.white70,
    ),
    bodyMedium: GoogleFonts.openSans(
      fontSize: 14,
      color: Colors.white70,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    foregroundColor: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3C3C3C), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.white70),
    hintStyle: const TextStyle(color: Colors.white38),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6C63FF),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: GoogleFonts.openSans(
        fontWeight: FontWeight.w600,
      ),
      elevation: 4,
      shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    tileColor: Color(0xFF1E1E1E),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E1E1E),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.4),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
  ),
  dividerTheme: DividerThemeData(
    color: Colors.white.withOpacity(0.1),
    thickness: 1,
  ),
  iconTheme: const IconThemeData(
    color: Colors.white70,
    size: 24,
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(SettingsModelAdapter());

  try {
    await Hive.openBox<TransactionModel>('transactions');
    await Hive.openBox<SettingsModel>('settings');

    final settingsBox = Hive.box<SettingsModel>('settings');
    if (!settingsBox.containsKey('user')) {
      await settingsBox.put('user', SettingsModel(
        isDarkMode: false,
        currency: 'CLP',
        useAuth: false,
        monthlySalary: 0.0,
        username: 'Usuario',
      ));
    }
  } catch (e) {
    debugPrint('Error al abrir las cajas: $e');
    await Hive.deleteBoxFromDisk('settings');
    await Hive.deleteBoxFromDisk('transactions');
    await Hive.openBox<TransactionModel>('transactions');
    await Hive.openBox<SettingsModel>('settings');

    final settingsBox = Hive.box<SettingsModel>('settings');
    await settingsBox.put('user', SettingsModel(
      isDarkMode: false,
      currency: 'CLP',
      useAuth: false,
      monthlySalary: 0.0,
      username: 'Usuario',
    ));
  }

  runApp(const FinviaApp());
}

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
