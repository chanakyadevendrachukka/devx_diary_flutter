import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../dashboard/dashboard_page.dart';
import '../diary/diary_list_page.dart';
import '../habits/habits_page.dart';
import '../routine/routine_page.dart';
import '../people/people_page.dart';
import '../vault/vault_page.dart';
import '../reminders/reminders_page.dart';
import '../settings/settings_page.dart';
import '../../utils/local_data_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  bool _showChecklist = true;

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
      body: Column(
        children: [_buildTodayChecklist(), Expanded(child: _pages[_index])],
      ),
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

  Widget _buildTodayChecklist() {
    if (!_showChecklist) return const SizedBox.shrink();
    return ValueListenableBuilder(
      valueListenable: LocalDataService.getBox('habits').listenable(),
      builder: (context, Box box, _) {
        final habits =
            box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (habits.isEmpty) return const SizedBox.shrink();

        final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final visible = habits.take(5).toList();

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.checklist, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Today\'s Checklist',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hide',
                        onPressed: () => setState(() => _showChecklist = false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...visible.map((habit) {
                    final completions = Map<String, dynamic>.from(
                      habit['completions'] ?? {},
                    );
                    final done = completions[dateKey] == true;
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        habit['name'] ?? 'Unnamed habit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        (habit['frequency'] ?? 'daily').toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      value: done,
                      onChanged: (_) => _toggleHabitCompletion(habit),
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _index = 2),
                      icon: const Icon(Icons.launch, size: 18),
                      label: const Text('Manage habits'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleHabitCompletion(Map<String, dynamic> habit) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final completions = Map<String, dynamic>.from(habit['completions'] ?? {});
    final current = completions[dateKey] == true;
    completions[dateKey] = !current;

    final updatedHabit = Map<String, dynamic>.from(habit);
    updatedHabit['completions'] = completions;
    await LocalDataService.saveData('habits', habit['id'], updatedHabit);
  }
}
