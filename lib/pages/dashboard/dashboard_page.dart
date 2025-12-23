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
  @override
  Widget build(BuildContext context) {
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
        final date = DateTime.parse(entry['date']);
        final key = DateFormat('yyyy-MM-dd').format(date);
        moodMap[key] = entry['mood'] ?? 'neutral';
      }
    }

    return Column(
      children: [
        // Days of week labels
        Row(
          children: [
            const SizedBox(width: 30),
            for (final day in ['Mon', 'Wed', 'Fri'])
              Expanded(
                flex: 2,
                child: Text(
                  day,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        // Heatmap grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week labels
            Column(
              children: List.generate(
                7,
                (i) => Container(
                  height: 20,
                  width: 30,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Grid
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(84, (index) {
                  final date = startDate.add(Duration(days: index));
                  final key = DateFormat('yyyy-MM-dd').format(date);
                  final mood = moodMap[key];
                  return _buildMoodCell(date, mood);
                }),
              ),
            ),
          ],
        ),
      ],
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
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
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
        final date = DateTime.parse(entry['date']);
        final key = DateFormat('yyyy-MM-dd').format(date);
        activityMap[key] = (activityMap[key] ?? 0) + 1;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 30),
            for (final day in ['Mon', 'Wed', 'Fri'])
              Expanded(
                flex: 2,
                child: Text(
                  day,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: List.generate(
                7,
                (i) => Container(
                  height: 20,
                  width: 30,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(84, (index) {
                  final date = startDate.add(Duration(days: index));
                  final key = DateFormat('yyyy-MM-dd').format(date);
                  final count = activityMap[key] ?? 0;
                  return _buildActivityCell(date, count);
                }),
              ),
            ),
          ],
        ),
      ],
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
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
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

        if (recentEntries.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No recent activity')),
            ),
          );
        }

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
