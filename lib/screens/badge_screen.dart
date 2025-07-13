import 'package:flutter/material.dart';
import '../widgets/badge_grid.dart';

class BadgeScreen extends StatelessWidget {
  const BadgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
        centerTitle: true,
      ),
      body: const BadgeGrid(),
    );
  }
}
