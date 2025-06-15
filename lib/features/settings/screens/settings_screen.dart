import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/settings_model.dart';
import '../../../core/utils/export_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _salaryController;
  final List<String> _availableCurrencies = ['CLP', 'USD', 'EUR', 'ARS'];

  @override
  void initState() {
    super.initState();
    _salaryController = TextEditingController();
    // Load initial salary value when the widget initializes
    final settingsBox = Hive.box<SettingsModel>('settings');
    final settings = settingsBox.get('user');
    if (settings != null) {
      _salaryController.text = settings.monthlySalary.toString();
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  void _showCurrencySelectionDialog(BuildContext context, SettingsModel currentSettings, Box<SettingsModel> box) {
    String tempSelectedCurrency = currentSettings.currency;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Seleccionar Moneda'),
          content: StatefulBuilder( // Use StatefulBuilder to update dialog content
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableCurrencies.length,
                  itemBuilder: (BuildContext context, int index) {
                    final currency = _availableCurrencies[index];
                    return RadioListTile<String>(
                      title: Text(currency),
                      value: currency,
                      groupValue: tempSelectedCurrency,
                      onChanged: (String? value) {
                        if (value != null) {
                          setStateDialog(() { // Use StateSetter for dialog
                            tempSelectedCurrency = value;
                          });
                        }
                      },
                    );
                  },
                ),
              );
            }
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                if (tempSelectedCurrency != currentSettings.currency) {
                  final newSettings = SettingsModel(
                    isDarkMode: currentSettings.isDarkMode,
                    currency: tempSelectedCurrency,
                    useAuth: currentSettings.useAuth,
                    monthlySalary: currentSettings.monthlySalary,
                    username: currentSettings.username, // Ensure username is preserved
                  );
                  box.put('user', newSettings);
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box<SettingsModel>('settings');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones'),
      ),
      body: ValueListenableBuilder(
        valueListenable: settingsBox.listenable(),
        builder: (context, Box<SettingsModel> box, _) {
          final settings = box.get('user');

          if (settings == null) {
            // This shouldn't happen if main.dart works fine, but it's a good guard.
            return const Center(child: Text("Cargando configuraciones..."));
          }

          // Update controller text if settings change from elsewhere,
          // but only if it's different to avoid cursor jumps.
          if (_salaryController.text != settings.monthlySalary.toString()) {
             _salaryController.text = settings.monthlySalary.toString();
             // Move cursor to the end
             _salaryController.selection = TextSelection.fromPosition(
                TextPosition(offset: _salaryController.text.length),
             );
          }


          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ListTile(
                leading: Icon(
                  settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Modo oscuro'),
                trailing: Switch(
                  value: settings.isDarkMode,
                  onChanged: (value) {
                    final newSettings = SettingsModel(
                      isDarkMode: value,
                      currency: settings.currency,
                      useAuth: settings.useAuth,
                      monthlySalary: settings.monthlySalary,
                      username: settings.username,
                    );
                    box.put('user', newSettings);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.attach_money,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Moneda'),
                subtitle: Text(settings.currency),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showCurrencySelectionDialog(context, settings, box);
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextFormField(
                  controller: _salaryController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Sueldo mensual',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    border: OutlineInputBorder(),
                  ),
                  onEditingComplete: () {
                    final salary = double.tryParse(_salaryController.text) ?? settings.monthlySalary;
                     if (salary != settings.monthlySalary) {
                        final updatedSettings = SettingsModel(
                          isDarkMode: settings.isDarkMode,
                          currency: settings.currency,
                          useAuth: settings.useAuth,
                          monthlySalary: salary,
                          username: settings.username,
                        );
                        box.put('user', updatedSettings);
                     }
                     // Dismiss keyboard
                     FocusScope.of(context).unfocus();
                  },
                ),
              ),
              const SizedBox(height: 12), // Adjusted spacing
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Exportar datos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text('Exportar como CSV'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        try {
                          final path = await exportTransactionsAsCSV();
                          if (context.mounted && path != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exportado a:\n$path'),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          } else if (context.mounted && path == null) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Falló la exportación de CSV.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al exportar CSV: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text('Exportar como JSON'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        try {
                          final path = await exportTransactionsAsJSON();
                           if (context.mounted && path != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exportado a:\n$path'),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          } else if (context.mounted && path == null) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Falló la exportación de JSON.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al exportar JSON: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Requerir autenticación al iniciar'),
                      value: settings.useAuth,
                       shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      onChanged: (value) {
                        final updated = SettingsModel(
                          isDarkMode: settings.isDarkMode,
                          currency: settings.currency,
                          useAuth: value,
                          monthlySalary: settings.monthlySalary,
                          username: settings.username,
                        );
                        box.put('user', updated);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
