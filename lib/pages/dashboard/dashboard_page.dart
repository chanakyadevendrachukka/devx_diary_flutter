import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../utils/local_data_service.dart';

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
    print('Dashboard page initialized');
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
      print('Dashboard boxes initialized successfully');
    } catch (e) {
      print('Dashboard initialization error: $e');
      // Retry after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkInitialization();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building dashboard, initialized: $_isInitialized');

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(),
          const SizedBox(height: 24),

          // Stats Cards
          _buildStatsCards(),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(context),
          const SizedBox(height: 24),

          // Mood Heatmap
          _buildMoodHeatmap(),
          const SizedBox(height: 24),

          // Entries Heatmap
          _buildEntriesHeatmap(),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat.yMMMMd().format(now),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
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

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Entries',
                        totalEntries.toString(),
                        Icons.book,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Streak',
                        '$streak days',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Habits',
                        totalHabits.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Reminders',
                        activeReminders.toString(),
                        Icons.alarm,
                        Colors.purple,
                      ),
                    ),
                  ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
                _buildActionButton('New Entry', Icons.edit, Colors.blue, () {
                  // Navigate to diary page
                  // This will be handled by the bottom nav
                }),
                _buildActionButton(
                  'Track Habit',
                  Icons.check_circle,
                  Colors.green,
                  () {},
                ),
                _buildActionButton(
                  'Add Reminder',
                  Icons.alarm,
                  Colors.purple,
                  () {},
                ),
                _buildActionButton(
                  'Add Person',
                  Icons.person_add,
                  Colors.orange,
                  () {},
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
