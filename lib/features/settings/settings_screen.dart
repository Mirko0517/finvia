import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import '../../../data/models/settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<SettingsModel>('settings').listenable(),
        builder: (context, Box<SettingsModel> box, _) {
          final settings = box.get('user') ?? SettingsModel(
            isDarkMode: false,
            currency: 'CLP',
            useAuth: true,
            monthlySalary: 0.0,
          );

          if (box.isEmpty) {
            box.put('user', settings);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              SwitchListTile(
                title: const Text('Modo oscuro'),
                value: settings.isDarkMode,
                onChanged: (value) {
                  setState(() {
                    settings.isDarkMode = value;
                    settings.save();
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Moneda'),
                value: settings.currency,
                items: ['CLP', 'USD', 'EUR', 'ARS']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      settings.currency = value;
                      settings.save();
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
