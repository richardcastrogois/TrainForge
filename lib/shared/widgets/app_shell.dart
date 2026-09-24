//lib/shared/widgets/app_shell.dart
import 'package:flutter/material.dart';
import 'package:trainforge/features/home/presentation/pages/home_page.dart';
import 'package:trainforge/features/profile/presentation/pages/profile_page.dart';
import 'package:trainforge/features/stats/presentation/pages/stats_page.dart';
import 'package:trainforge/features/workouts/presentation/pages/workouts_page.dart';
import 'package:trainforge/shared/widgets/app_bottom_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    WorkoutsPage(),
    StatsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}
