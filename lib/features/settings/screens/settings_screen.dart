import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/settings_model.dart';
import '../../../core/utils/export_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          final settings = box.get('user')!;

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
                    final currentSettings = box.get('user')!;
                    final newSettings = SettingsModel(
                      isDarkMode: value,
                      currency: currentSettings.currency,
                      useAuth: currentSettings.useAuth,
                      monthlySalary: currentSettings.monthlySalary,
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
                  // TODO: Implementar selección de moneda
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  initialValue: settings.monthlySalary.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sueldo mensual',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  onChanged: (value) {
                    final salary = double.tryParse(value) ?? 0.0;
                    final updated = SettingsModel(
                      isDarkMode: settings.isDarkMode,
                      currency: settings.currency,
                      useAuth: settings.useAuth,
                      monthlySalary: salary,
                    );
                    Hive.box<SettingsModel>('settings').put('user', updated);
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Exportar datos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text('Exportar como CSV'),
                      onPressed: () async {
                        try {
                          final path = await exportTransactionsAsCSV();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exportado a:\n$path'),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al exportar: $e'),
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
                      onPressed: () async {
                        try {
                          final path = await exportTransactionsAsJSON();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exportado a:\n$path'),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al exportar: $e'),
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
                      onChanged: (value) {
                        final updated = SettingsModel(
                          isDarkMode: settings.isDarkMode,
                          currency: settings.currency,
                          useAuth: value,
                          monthlySalary: settings.monthlySalary,
                        );
                        Hive.box<SettingsModel>('settings').put('user', updated);
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
