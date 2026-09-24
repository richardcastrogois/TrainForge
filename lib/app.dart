//lib/app.dart
import 'package:flutter/material.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';

class TrainForgeApp extends StatelessWidget {
  const TrainForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrainForge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
