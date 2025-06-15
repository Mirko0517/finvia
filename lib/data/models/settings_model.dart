import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 1)
class SettingsModel extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  String currency;

  @HiveField(2)
  final bool useAuth;

  @HiveField(3)
  final double monthlySalary;

  @HiveField(4)
  final String username;

  SettingsModel({
    required this.isDarkMode,
    required this.currency,
    required this.useAuth,
    required this.monthlySalary,
    this.username = '',
  });
}
