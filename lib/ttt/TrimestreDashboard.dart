import 'package:flutter/material.dart';
import './classcards.dart';

class TrimestreScreen extends StatelessWidget {
  const TrimestreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TrimestreCard(
                title: '1er Trimestre',
                onTap: () {
                  // TODO: Handle navigation or action
                },
              ),
              const SizedBox(height: 20),
              TrimestreCard(
                title: '2ème Trimestre',
                onTap: () {
                  // TODO: Handle navigation or action
                },
              ),
              const SizedBox(height: 20),
              TrimestreCard(
                title: '3ème Trimestre',
                onTap: () {
                  // TODO: Handle navigation or action
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
