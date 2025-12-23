import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../utils/local_data_service.dart';
import '../../utils/sync_manager.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final _nameController = TextEditingController();
  String _frequency = 'daily';
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkAndSync();
  }

  Future<void> _checkAndSync() async {
    if (await LocalDataService.needsSync()) {
      await SyncManager.syncNow();
    }
  }

  Future<void> _addHabit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final habitId = const Uuid().v4();
    await LocalDataService.saveData('habits', habitId, {
      'id': habitId,
      'name': name,
      'frequency': _frequency,
      'startDate': _startDate.toIso8601String(),
      'completions': <String, bool>{},
      'createdAt': DateTime.now().toIso8601String(),
    });
    _nameController.clear();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleCompletion(Map<String, dynamic> habit) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final completions = Map<String, dynamic>.from(habit['completions'] ?? {});
    final current = completions[dateKey] == true;
    completions[dateKey] = !current;

    final updatedHabit = Map<String, dynamic>.from(habit);
    updatedHabit['completions'] = completions;
    await LocalDataService.saveData('habits', habit['id'], updatedHabit);
  }

  int _streak(Map<String, dynamic>? completions) {
    if (completions == null || completions.isEmpty) return 0;
    int streak = 0;
    final today = DateTime.now();
    DateTime cursor = DateTime(today.year, today.month, today.day);
    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(cursor);
      if (completions[key] == true) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder:
                          (context) => SafeArea(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.add_task,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'New Habit',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Habit name',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _frequency,
                                      decoration: const InputDecoration(
                                        labelText: 'Frequency',
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'daily',
                                          child: Text('Daily'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'weekly',
                                          child: Text('Weekly'),
                                        ),
                                      ],
                                      onChanged:
                                          (v) => setState(
                                            () => _frequency = v ?? 'daily',
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate: _startDate,
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime(2100),
                                                  );
                                              if (picked != null) {
                                                setState(
                                                  () => _startDate = picked,
                                                );
                                              }
                                            },
                                            child: InputDecorator(
                                              decoration: const InputDecoration(
                                                labelText: 'Start date',
                                              ),
                                              child: Text(
                                                DateFormat.yMMMd().format(
                                                  _startDate,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: _addHabit,
                                        child: const Text('Create habit'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    );
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('New habit'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: LocalDataService.getBox('habits').listenable(),
            builder: (context, Box box, _) {
              final habits =
                  box.values
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();

              // Sort by creation date descending
              habits.sort((a, b) {
                final dateA =
                    a['createdAt'] != null
                        ? DateTime.parse(a['createdAt'])
                        : DateTime.now();
                final dateB =
                    b['createdAt'] != null
                        ? DateTime.parse(b['createdAt'])
                        : DateTime.now();
                return dateB.compareTo(dateA);
              });

              if (habits.isEmpty) {
                return const Center(child: Text('No habits yet'));
              }
              return ListView.separated(
                itemCount: habits.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  final name = habit['name'] as String? ?? '';
                  final frequency = habit['frequency'] as String? ?? 'daily';
                  final completions = Map<String, dynamic>.from(
                    habit['completions'] ?? {},
                  );
                  final streak = _streak(completions);
                  final todayKey = DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.now());
                  final isCompletedToday = completions[todayKey] == true;

                  return ListTile(
                    title: Text(name),
                    subtitle: Text('Frequency: $frequency • Streak: $streak'),
                    trailing: IconButton(
                      tooltip: 'Mark complete for today',
                      onPressed: () => _toggleCompletion(habit),
                      icon: Icon(
                        isCompletedToday
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: isCompletedToday ? Colors.green : null,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
