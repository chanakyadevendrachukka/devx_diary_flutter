import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dashboard/dashboard_page.dart';
import '../diary/diary_list_page.dart';
import '../habits/habits_page.dart';
import '../routine/routine_page.dart';
import '../people/people_page.dart';
import '../vault/vault_page.dart';
import '../reminders/reminders_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final _pages = const [
    DashboardPage(),
    DiaryListPage(),
    HabitsPage(),
    RoutinePage(),
    PeoplePage(),
    VaultPage(),
    RemindersPage(),
    SettingsPage(),
  ];

  final _labels = const [
    'Dashboard',
    'Diary',
    'Habits',
    'Routine',
    'People',
    'Vault',
    'Reminders',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_labels[_index]),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth * 2,
              ),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.book_outlined),
                    selectedIcon: Icon(Icons.book),
                    label: 'Diary',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.check_circle_outline),
                    selectedIcon: Icon(Icons.check_circle),
                    label: 'Habits',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.view_agenda_outlined),
                    selectedIcon: Icon(Icons.view_agenda),
                    label: 'Routine',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_alt_outlined),
                    selectedIcon: Icon(Icons.people_alt),
                    label: 'People',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.lock_outline),
                    selectedIcon: Icon(Icons.lock),
                    label: 'Vault',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.alarm_add_outlined),
                    selectedIcon: Icon(Icons.alarm_add),
                    label: 'Reminders',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
