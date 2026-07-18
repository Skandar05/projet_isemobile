import 'package:shared_preferences/shared_preferences.dart';

Future<void> clearAllPreferences() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.clear();

  print("All SharedPreferences cleared");
}