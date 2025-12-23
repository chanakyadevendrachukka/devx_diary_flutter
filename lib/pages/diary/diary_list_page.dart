import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../utils/ui_helpers.dart';
import '../../utils/local_data_service.dart';
import '../../utils/sync_manager.dart';
import 'diary_editor_page.dart';

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  String _query = '';
  DateTime? _selectedDate;
  CalendarFormat _calendarFormat = CalendarFormat.week;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by title or tag…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged:
                      (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Add entry',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DiaryEditorPage()),
                  );
                  setState(() {}); // Refresh after adding
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TableCalendar(
            firstDay: DateTime(2010),
            lastDay: DateTime(2100),
            focusedDay: _selectedDate ?? DateTime.now(),
            calendarFormat: _calendarFormat,
            onFormatChanged: (f) => setState(() => _calendarFormat = f),
            selectedDayPredicate:
                (d) => _selectedDate != null && isSameDay(_selectedDate, d),
            onDaySelected: (d, _) => setState(() => _selectedDate = d),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: LocalDataService.getBox('entries').listenable(),
            builder: (context, Box box, _) {
              final allEntries =
                  box.values
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();

              final filteredEntries =
                  allEntries.where((data) {
                    final title =
                        (data['title'] ?? '').toString().toLowerCase();
                    final tags =
                        (data['tags'] as List?)
                            ?.map((e) => e.toString().toLowerCase())
                            .toList() ??
                        [];
                    final date =
                        data['date'] != null
                            ? DateTime.parse(data['date'])
                            : null;

                    final matchesQuery =
                        _query.isEmpty ||
                        title.contains(_query) ||
                        tags.any((t) => t.contains(_query));

                    final matchesDate =
                        _selectedDate == null ||
                        (date != null && isSameDay(date, _selectedDate));

                    return matchesQuery && matchesDate;
                  }).toList();

              // Sort by date descending
              filteredEntries.sort((a, b) {
                final dateA =
                    a['date'] != null
                        ? DateTime.parse(a['date'])
                        : DateTime.now();
                final dateB =
                    b['date'] != null
                        ? DateTime.parse(b['date'])
                        : DateTime.now();
                return dateB.compareTo(dateA);
              });

              if (filteredEntries.isEmpty) {
                return const Center(
                  child: Text('No entries yet. Tap + to add.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: filteredEntries.length,
                itemBuilder: (context, index) {
                  final data = filteredEntries[index];
                  final entryId = data['id'] ?? '';
                  final date =
                      data['date'] != null
                          ? DateTime.parse(data['date'])
                          : DateTime.now();
                  final mood = (data['mood'] ?? 'neutral') as String;

                  return UIHelpers.customListTile(
                    context: context,
                    leading: _moodIcon(mood),
                    leadingColor: _moodColor(mood),
                    title: data['title'] ?? '(untitled)',
                    subtitle: DateFormat.yMMMd().add_jm().format(date),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => DiaryEditorPage(
                                entryId: entryId,
                                initialData: data,
                              ),
                        ),
                      );
                      setState(() {}); // Refresh after editing
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _moodIcon(String mood) {
    switch (mood) {
      case 'happy':
        return Icons.sentiment_satisfied_alt;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      case 'calm':
        return Icons.self_improvement;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _moodColor(String mood) {
    switch (mood) {
      case 'happy':
        return Colors.orange;
      case 'sad':
        return Colors.blueGrey;
      case 'angry':
        return Colors.redAccent;
      case 'calm':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
