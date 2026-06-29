import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/student_provider.dart';

import 'package:test/providers/Rdv_provider.dart';
import 'package:test/Screens/parent/creationRDV.dart';


import 'providers/auth_provider.dart';
import 'Screens/Auth/Auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentProvider()..loadStudent()),
        ChangeNotifierProvider( create: (_) => AuthProvider(), child: const MyApp(), ),
        
        ChangeNotifierProvider(create: (_) => RdvProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthScreen(),
    );
  }
}
