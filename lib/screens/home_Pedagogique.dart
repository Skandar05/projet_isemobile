import 'package:flutter/material.dart';

import 'role_home.dart';

class HomeCScreen extends StatelessWidget {
  const HomeCScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeScreen(
      title: 'Home Pédagogique',
      subtitle: 'You are logged in as role pédagogique.',
      accent: Color(0xFF1D4ED8),
    );
  }
}