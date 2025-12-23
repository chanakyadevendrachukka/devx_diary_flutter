import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../services/notification_service.dart';
import '../../utils/local_data_service.dart';
import '../diary/diary_editor_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  void _checkInitialization() {
    try {
      // Check if Hive boxes are accessible
      LocalDataService.getBox('entries');
      LocalDataService.getBox('habits');
      LocalDataService.getBox('reminders');
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // Retry after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkInitialization();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final surface = Theme.of(context).colorScheme.surfaceVariant;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [surface, surface.withOpacity(0.4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 16),
              _buildStatsCards(),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 16),
              _buildUpcomingReminders(),
              const SizedBox(height: 16),
              _buildHabitHighlights(),
              const SizedBox(height: 16),
              _buildMoodHeatmap(),
              const SizedBox(height: 16),
              _buildEntriesHeatmap(),
              const SizedBox(height: 16),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    IconData icon;

    if (hour < 12) {
      greeting = 'Good Morning';
      icon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      icon = Icons.sunny;
    } else {
      greeting = 'Good Evening';
      icon = Icons.nights_stay;
    }

    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.12), accent.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.EEEE().add_yMMMMd().format(now),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Today',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat.jm().format(now),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return ValueListenableBuilder(
      valueListenable: LocalDataService.getBox('entries').listenable(),
      builder: (context, Box diaryBox, _) {
        return ValueListenableBuilder(
          valueListenable: LocalDataService.getBox('habits').listenable(),
          builder: (context, Box habitsBox, _) {
            return ValueListenableBuilder(
              valueListenable:
                  LocalDataService.getBox('reminders').listenable(),
              builder: (context, Box remindersBox, _) {
                final totalEntries = diaryBox.length;
                final totalHabits = habitsBox.length;
                final activeReminders =
                    remindersBox.values.where((r) {
                      final data = Map<String, dynamic>.from(r as Map);
                      return data['status'] == 'scheduled';
                    }).length;

                // Calculate streak
                final entries =
                    diaryBox.values
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList();
                final streak = _calculateStreak(entries);

                final stats = [
                  _buildStatCard(
                    'Entries',
                    totalEntries.toString(),
                    Icons.book,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Streak',
                    '$streak days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Habits',
                    totalHabits.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Reminders',
                    activeReminders.toString(),
                    Icons.alarm,
                    Colors.purple,
                  ),
                ];

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 700;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children:
                          stats
                              .map(
                                (card) => SizedBox(
                                  width:
                                      isNarrow
                                          ? (constraints.maxWidth - 12) / 2
                                          : (constraints.maxWidth - 12 * 3) / 4,
                                  child: card,
                                ),
                              )
                              .toList(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  'New Entry',
                  Icons.edit,
                  Colors.blue,
                  _openQuickDiary,
                ),
                _buildActionButton(
                  'Track Habit',
                  Icons.check_circle,
                  Colors.green,
                  _showQuickHabitSheet,
                ),
                _buildActionButton(
                  'Add Reminder',
                  Icons.alarm,
                  Colors.purple,
                  _showQuickReminderSheet,
                ),
                _buildActionButton(
                  'Add Person',
                  Icons.person_add,
                  Colors.orange,
                  _showQuickPersonSheet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingReminders() {
    return ValueListenableBuilder(
      valueListenable: LocalDataService.getBox('reminders').listenable(),
      builder: (context, Box box, _) {
        final reminders =
            box.values
                .map((e) => Map<String, dynamic>.from(e as Map))
                .where((r) => r['scheduledAt'] != null)
                .toList()
              ..sort((a, b) {
                final aDate =
                    DateTime.tryParse(a['scheduledAt'] ?? '') ?? DateTime.now();
                final bDate =
                    DateTime.tryParse(b['scheduledAt'] ?? '') ?? DateTime.now();
                return aDate.compareTo(bDate);
              });

        final upcoming = reminders.take(3).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.alarm,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upcoming reminders',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (upcoming.isEmpty)
                  _buildEmptyPlaceholder(
                    icon: Icons.alarm_add_outlined,
                    title: 'No reminders yet',
                    message: 'Schedule a reminder to see it here.',
                  )
                else
                  ...upcoming.map((reminder) {
                    final when =
                        DateTime.tryParse(reminder['scheduledAt'] ?? '') ??
                        DateTime.now();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active, size: 20),
                      ),
                      title: Text(reminder['title'] ?? 'Untitled'),
                      subtitle: Text(DateFormat.yMMMd().add_jm().format(when)),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade500,
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHabitHighlights() {
    return ValueListenableBuilder(
      valueListenable: LocalDataService.getBox('habits').listenable(),
      builder: (context, Box box, _) {
        final habits =
            box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              ..sort(
                (a, b) => _habitStreak(
                  b['completions'],
                ).compareTo(_habitStreak(a['completions'])),
              );

        final topHabits = habits.take(3).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Habit highlights',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (topHabits.isEmpty)
                  _buildEmptyPlaceholder(
                    icon: Icons.check_circle_outline,
                    title: 'No habits tracked',
                    message: 'Create a habit to start tracking streaks.',
                  )
                else
                  ...topHabits.map((habit) {
                    final streak = _habitStreak(habit['completions']);
                    final freq = (habit['frequency'] ?? 'daily').toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit['name'] ?? 'Unnamed',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${freq[0].toUpperCase()}${freq.substring(1)} · Streak $streak',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('Day $streak'),
                            backgroundColor: Colors.green.withOpacity(0.12),
                            labelStyle: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openQuickDiary() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DiaryEditorPage()));
  }

  Future<void> _showQuickHabitSheet() async {
    final nameController = TextEditingController();
    String frequency = 'daily';
    DateTime startDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Habit name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    ],
                    onChanged:
                        (v) => setSheetState(() {
                          frequency = v ?? 'daily';
                        }),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setSheetState(() => startDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start date',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat.yMMMd().format(startDate)),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        final id = const Uuid().v4();
                        await LocalDataService.saveData('habits', id, {
                          'id': id,
                          'name': name,
                          'frequency': frequency,
                          'startDate': startDate.toIso8601String(),
                          'completions': <String, bool>{},
                          'createdAt': DateTime.now().toIso8601String(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Habit added: $name')),
                          );
                        }
                      },
                      child: const Text('Create habit'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showQuickReminderSheet() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime scheduledAt = DateTime.now().add(const Duration(hours: 1));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Reminder title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: scheduledAt,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(scheduledAt),
                      );
                      if (time == null) return;
                      setSheetState(() {
                        scheduledAt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Schedule'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat.yMMMd().add_jm().format(scheduledAt)),
                          const Icon(Icons.schedule, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;
                        final id = const Uuid().v4();
                        final reminderData = {
                          'id': id,
                          'title': title,
                          'description': descController.text.trim(),
                          'scheduledAt': scheduledAt.toIso8601String(),
                          'status': 'scheduled',
                          'createdAt': DateTime.now().toIso8601String(),
                        };

                        await LocalDataService.saveData(
                          'reminders',
                          id,
                          reminderData,
                        );

                        await NotificationService.scheduleReminder(
                          id: id,
                          title: title,
                          description: descController.text.trim(),
                          scheduledTime: scheduledAt,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reminder set for ${DateFormat.jm().format(scheduledAt)}',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Schedule reminder'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showQuickPersonSheet() async {
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final id = const Uuid().v4();
                    await LocalDataService.saveData('people', id, {
                      'id': id,
                      'name': name,
                      'notes': notesController.text.trim(),
                      'createdAt': DateTime.now().toIso8601String(),
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Person added: $name')),
                      );
                    }
                  },
                  child: const Text('Add person'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodHeatmap() {
    return ValueListenableBuilder(
      valueListenable: LocalDataService.getBox('entries').listenable(),
      builder: (context, Box box, _) {
        final entries =
            box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.mood,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mood Tracker',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMoodHeatmapGrid(entries),
                const SizedBox(height: 16),
                _buildMoodLegend(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodHeatmapGrid(List<Map<String, dynamic>> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 83)); // 12 weeks

    // Create mood map
    final moodMap = <String, String>{};
    for (final entry in entries) {
      if (entry['date'] != null) {
        try {
          final date = DateTime.parse(entry['date']);
          final key = DateFormat('yyyy-MM-dd').format(date);
          moodMap[key] = entry['mood'] ?? 'neutral';
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    }

    // Create grid of 12 weeks (84 days) organized by week
    final weeks = <List<DateTime>>[];
    for (int week = 0; week < 12; week++) {
      final weekDays = <DateTime>[];
      for (int day = 0; day < 7; day++) {
        final date = startDate.add(Duration(days: week * 7 + day));
        if (!date.isAfter(today)) {
          weekDays.add(date);
        }
      }
      if (weekDays.isNotEmpty) {
        weeks.add(weekDays);
      }
    }

    return SizedBox(
      height: 160,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(
                  (day) => SizedBox(
                    height: 18,
                    child: Text(
                      day,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Week columns
            ...weeks.map((weekDays) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ...List.generate(7, (dayIndex) {
                      if (dayIndex < weekDays.length) {
                        final date = weekDays[dayIndex];
                        final key = DateFormat('yyyy-MM-dd').format(date);
                        final mood = moodMap[key];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _buildMoodCell(date, mood),
                        );
                      }
                      return const SizedBox(height: 14, width: 14);
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCell(DateTime date, String? mood) {
    Color color;
    if (mood == null) {
      color = Colors.grey.shade200;
    } else {
      color = _getMoodColor(mood);
    }

    return Tooltip(
      message: '${DateFormat.MMMd().format(date)}\n${mood ?? 'No entry'}',
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
    );
  }

  Widget _buildMoodLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('Happy', _getMoodColor('happy')),
        _buildLegendItem('Calm', _getMoodColor('calm')),
        _buildLegendItem('Neutral', _getMoodColor('neutral')),
        _buildLegendItem('Sad', _getMoodColor('sad')),
        _buildLegendItem('Angry', _getMoodColor('angry')),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildEntriesHeatmap() {
    return ValueListenableBuilder(
      valueListenable: LocalDataService.getBox('entries').listenable(),
      builder: (context, Box box, _) {
        final entries =
            box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Activity Heatmap',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivityHeatmapGrid(entries),
                const SizedBox(height: 16),
                _buildActivityLegend(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityHeatmapGrid(List<Map<String, dynamic>> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 83));

    // Count entries per day
    final activityMap = <String, int>{};
    for (final entry in entries) {
      if (entry['date'] != null) {
        try {
          final date = DateTime.parse(entry['date']);
          final key = DateFormat('yyyy-MM-dd').format(date);
          activityMap[key] = (activityMap[key] ?? 0) + 1;
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    }

    // Create grid of 12 weeks (84 days) organized by week
    final weeks = <List<DateTime>>[];
    for (int week = 0; week < 12; week++) {
      final weekDays = <DateTime>[];
      for (int day = 0; day < 7; day++) {
        final date = startDate.add(Duration(days: week * 7 + day));
        if (!date.isAfter(today)) {
          weekDays.add(date);
        }
      }
      if (weekDays.isNotEmpty) {
        weeks.add(weekDays);
      }
    }

    return SizedBox(
      height: 160,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(
                  (day) => SizedBox(
                    height: 18,
                    child: Text(
                      day,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Week columns
            ...weeks.map((weekDays) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ...List.generate(7, (dayIndex) {
                      if (dayIndex < weekDays.length) {
                        final date = weekDays[dayIndex];
                        final key = DateFormat('yyyy-MM-dd').format(date);
                        final count = activityMap[key] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _buildActivityCell(date, count),
                        );
                      }
                      return const SizedBox(height: 14, width: 14);
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCell(DateTime date, int count) {
    Color color;
    if (count == 0) {
      color = Colors.grey.shade200;
    } else if (count == 1) {
      color = Colors.green.shade200;
    } else if (count == 2) {
      color = Colors.green.shade400;
    } else {
      color = Colors.green.shade700;
    }

    return Tooltip(
      message:
          '${DateFormat.MMMd().format(date)}\n$count ${count == 1 ? 'entry' : 'entries'}',
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
    );
  }

  Widget _buildActivityLegend() {
    return Row(
      children: [
        const Text('Less', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 8),
        ...List.generate(4, (i) {
          final colors = [
            Colors.grey.shade200,
            Colors.green.shade200,
            Colors.green.shade400,
            Colors.green.shade700,
          ];
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[i],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        const Text('More', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return ValueListenableBuilder(
      valueListenable: LocalDataService.getBox('entries').listenable(),
      builder: (context, Box box, _) {
        final entries =
            box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              ..sort((a, b) {
                final dateA =
                    DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
                final dateB =
                    DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);
                return dateB.compareTo(dateA);
              });

        final recentEntries = entries.take(5).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Entries',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (recentEntries.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No entries yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start writing your first diary entry',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentEntries.map((entry) => _buildActivityItem(entry)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> entry) {
    final date = DateTime.tryParse(entry['date'] ?? '') ?? DateTime.now();
    final mood = entry['mood'] ?? 'neutral';
    final title = entry['title'] ?? 'Untitled';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getMoodColor(mood).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMoodIcon(mood),
              color: _getMoodColor(mood),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat.yMMMd().format(date),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _habitStreak(Map<String, dynamic>? completions) {
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

  int _calculateStreak(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) return 0;

    final sortedDates =
        entries
            .where((e) => e['date'] != null)
            .map((e) => DateTime.parse(e['date']))
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    // Check if streak is current (today or yesterday has entry)
    if (!sortedDates.contains(todayDate) && !sortedDates.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime currentDate = todayDate;

    while (sortedDates.contains(currentDate)) {
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy':
        return Colors.amber;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'calm':
        return Colors.green;
      case 'neutral':
      default:
        return Colors.grey;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      case 'calm':
        return Icons.self_improvement;
      case 'neutral':
      default:
        return Icons.sentiment_neutral;
    }
  }
}
