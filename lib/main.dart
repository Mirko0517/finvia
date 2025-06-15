import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/transaction_model.dart';
import 'data/models/settings_model.dart';
import 'features/main/screens/main_screen.dart';
import 'features/transactions/screens/new_transaction_screen.dart';
import 'package:finvia_flutter/core/theme/app_theme.dart';
import 'package:finvia_flutter/core/utils/app_constants.dart';
import 'package:finvia_flutter/app.dart';

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
      await _applyDefaultSettings(settingsBox);
    }
  } on HiveError catch (e) {
    debugPrint('HiveError during initial box opening: $e');
    if (e.message.contains('transactions')) {
      debugPrint('Error specifically opening transactions box. Attempting recovery...');
      try {
        await Hive.deleteBoxFromDisk('transactions');
        await Hive.openBox<TransactionModel>('transactions');
        debugPrint('Transactions box recovered.');
      } catch (recoveryError) {
        debugPrint('Failed to recover transactions box: $recoveryError');
        // Optionally, rethrow or handle as fatal
        rethrow;
      }
    } else if (e.message.contains('settings')) {
      debugPrint('Error specifically opening settings box. Attempting recovery...');
      try {
        await Hive.deleteBoxFromDisk('settings');
        final settingsBox = await Hive.openBox<SettingsModel>('settings');
        debugPrint('Settings box recovered. Applying default settings.');
        await _applyDefaultSettings(settingsBox);
      } catch (recoveryError) {
        debugPrint('Failed to recover settings box: $recoveryError');
        // Optionally, rethrow or handle as fatal
        rethrow;
      }
    } else {
      // General HiveError, attempt to recover both
      debugPrint('Unspecified HiveError. Attempting to recover both boxes...');
      try {
        await Hive.deleteBoxFromDisk('settings');
        await Hive.deleteBoxFromDisk('transactions');
        await Hive.openBox<TransactionModel>('transactions');
        final settingsBox = await Hive.openBox<SettingsModel>('settings');
        debugPrint('Both boxes recovered. Applying default settings.');
        await _applyDefaultSettings(settingsBox);
      } catch (recoveryError) {
        debugPrint('Failed to recover both boxes: $recoveryError');
        // Optionally, rethrow or handle as fatal
        rethrow;
      }
    }
  } catch (e) {
    // Catch any other non-Hive errors during the initial setup
    debugPrint('An unexpected error occurred during Hive initialization: $e');
    // Depending on the app's requirements, this might be a fatal error.
    // For now, we'll try a full reset as a last resort, similar to the old behavior.
    try {
      debugPrint('Attempting a full reset of Hive boxes as a last resort...');
      await Hive.deleteBoxFromDisk('settings');
      await Hive.deleteBoxFromDisk('transactions');
      await Hive.openBox<TransactionModel>('transactions');
      final settingsBox = await Hive.openBox<SettingsModel>('settings');
      debugPrint('Full reset successful. Applying default settings.');
      await _applyDefaultSettings(settingsBox);
    } catch (resetError) {
      debugPrint('Full reset failed: $resetError');
      // At this point, the app is likely in an unusable state regarding local storage.
      // Rethrowing or displaying a fatal error message to the user would be appropriate.
      rethrow;
    }
  }

  runApp(const FinviaApp());
}

Future<void> _applyDefaultSettings(Box<SettingsModel> settingsBox) async {
  if (!settingsBox.containsKey('user')) {
    await settingsBox.put('user', SettingsModel(
      isDarkMode: kDefaultIsDarkMode,
      currency: kDefaultCurrency,
      useAuth: kDefaultUseAuth,
      monthlySalary: kDefaultMonthlySalary,
      username: kDefaultUsername,
    ));
    debugPrint('Default settings applied.');
  }
}
