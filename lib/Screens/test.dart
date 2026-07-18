import 'package:shared_preferences/shared_preferences.dart';

Future<void> printSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();

  final keys = prefs.getKeys();

  print("===== SharedPreferences =====");

  for (String key in keys) {
    print("$key : ${prefs.get(key)}");
  }

  print("=============================");
}