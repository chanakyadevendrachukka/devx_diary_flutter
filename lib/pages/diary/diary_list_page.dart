import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../utils/local_data_service.dart';
import '../../utils/sync_manager.dart';
import 'diary_editor_page.dart';
import 'diary_reader_page.dart';

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  String _query = '';
  DateTime? _selectedDate;
  String? _selectedMood;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _showCalendar = false;
  bool _isGridView = false;
  String _sortBy = 'date_desc'; // date_desc, date_asc, title

  @override
  void initState() {
    super.initState();
    // Defer sync work and guard against remote permission failures so UI still builds.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndSync());
  }

  Future<void> _checkAndSync() async {
    try {
      if (await LocalDataService.needsSync()) {
        await SyncManager.syncNow();
      }
    } catch (e) {
      // Keep local experience functional even if remote sync fails (e.g., Firestore disabled).
      debugPrint('Sync failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sync failed. Check Firestore access or try again later.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilters(),
          if (_showCalendar) _buildCalendar(),
          Expanded(child: _buildEntriesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewEntry,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search entries...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _query.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _query = ''),
                      )
                      : null,
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  avatar: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _selectedDate == null
                        ? 'All Dates'
                        : DateFormat.MMMd().format(_selectedDate!),
                  ),
                  selected: _selectedDate != null,
                  onSelected:
                      (_) => setState(() => _showCalendar = !_showCalendar),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(_getMoodIcon('happy'), size: 18),
                  label: const Text('Happy'),
                  selected: _selectedMood == 'happy',
                  onSelected:
                      (v) => setState(() => _selectedMood = v ? 'happy' : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(_getMoodIcon('sad'), size: 18),
                  label: const Text('Sad'),
                  selected: _selectedMood == 'sad',
                  onSelected:
                      (v) => setState(() => _selectedMood = v ? 'sad' : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(_getMoodIcon('calm'), size: 18),
                  label: const Text('Calm'),
                  selected: _selectedMood == 'calm',
                  onSelected:
                      (v) => setState(() => _selectedMood = v ? 'calm' : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(_getMoodIcon('angry'), size: 18),
                  label: const Text('Angry'),
                  selected: _selectedMood == 'angry',
                  onSelected:
                      (v) => setState(() => _selectedMood = v ? 'angry' : null),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort',
                  onSelected: (value) => setState(() => _sortBy = value),
                  itemBuilder:
                      (context) => [
                        CheckedPopupMenuItem(
                          value: 'date_desc',
                          checked: _sortBy == 'date_desc',
                          child: const Text('Newest First'),
                        ),
                        CheckedPopupMenuItem(
                          value: 'date_asc',
                          checked: _sortBy == 'date_asc',
                          child: const Text('Oldest First'),
                        ),
                        CheckedPopupMenuItem(
                          value: 'title',
                          checked: _sortBy == 'title',
                          child: const Text('Title A-Z'),
                        ),
                      ],
                ),
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                  tooltip: _isGridView ? 'List View' : 'Grid View',
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2010),
        lastDay: DateTime(2100),
        focusedDay: _selectedDate ?? DateTime.now(),
        calendarFormat: _calendarFormat,
        onFormatChanged: (f) => setState(() => _calendarFormat = f),
        selectedDayPredicate:
            (d) => _selectedDate != null && isSameDay(_selectedDate, d),
        onDaySelected: (d, _) {
          setState(() {
            _selectedDate = isSameDay(d, _selectedDate) ? null : d;
          });
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    return ValueListenableBuilder(
      valueListenable: LocalDataService.getBox('entries').listenable(),
      builder: (context, Box box, _) {
        var entries =
            box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        // Apply filters
        entries =
            entries.where((data) {
              final title = (data['title'] ?? '').toString().toLowerCase();
              final content = (data['content'] ?? '').toString().toLowerCase();
              final tags =
                  (data['tags'] as List?)
                      ?.map((e) => e.toString().toLowerCase())
                      .toList() ??
                  [];
              final date =
                  data['date'] != null ? DateTime.parse(data['date']) : null;
              final mood = data['mood'] ?? 'neutral';

              final matchesQuery =
                  _query.isEmpty ||
                  title.contains(_query) ||
                  content.contains(_query) ||
                  tags.any((t) => t.contains(_query));

              final matchesDate =
                  _selectedDate == null ||
                  (date != null && isSameDay(date, _selectedDate));

              final matchesMood =
                  _selectedMood == null || mood == _selectedMood;

              return matchesQuery && matchesDate && matchesMood;
            }).toList();

        // Apply sorting
        entries.sort((a, b) {
          switch (_sortBy) {
            case 'date_asc':
              final dateA =
                  a['date'] != null
                      ? DateTime.parse(a['date'])
                      : DateTime.now();
              final dateB =
                  b['date'] != null
                      ? DateTime.parse(b['date'])
                      : DateTime.now();
              return dateA.compareTo(dateB);
            case 'title':
              return (a['title'] ?? '').toString().compareTo(
                (b['title'] ?? '').toString(),
              );
            case 'date_desc':
            default:
              final dateA =
                  a['date'] != null
                      ? DateTime.parse(a['date'])
                      : DateTime.now();
              final dateB =
                  b['date'] != null
                      ? DateTime.parse(b['date'])
                      : DateTime.now();
              return dateB.compareTo(dateA);
          }
        });

        if (entries.isEmpty) {
          return _buildEmptyState();
        }

        return _isGridView ? _buildGridView(entries) : _buildListView(entries);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No entries yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your journal journey',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewEntry(),
            icon: const Icon(Icons.add),
            label: const Text('Create First Entry'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> entries) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final data = entries[index];
        return _buildEntryCard(data);
      },
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> entries) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final data = entries[index];
        return _buildGridCard(data);
      },
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> data) {
    final entryId = data['id'] ?? '';
    final title = data['title'] ?? 'Untitled';
    final content = data['content'] ?? '';
    final date =
        data['date'] != null ? DateTime.parse(data['date']) : DateTime.now();
    final mood = data['mood'] ?? 'neutral';
    final tags =
        (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openEntry(entryId, data),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat.yMMMd().add_jm().format(date),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editEntry(entryId, data);
                      } else if (value == 'delete') {
                        _deleteEntry(entryId, title);
                      }
                    },
                  ),
                ],
              ),
              if (content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$tag',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> data) {
    final entryId = data['id'] ?? '';
    final title = data['title'] ?? 'Untitled';
    final content = data['content'] ?? '';
    final date =
        data['date'] != null ? DateTime.parse(data['date']) : DateTime.now();
    final mood = data['mood'] ?? 'neutral';

    return Card(
      child: InkWell(
        onTap: () => _openEntry(entryId, data),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getMoodColor(mood).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getMoodIcon(mood),
                      color: _getMoodColor(mood),
                      size: 18,
                    ),
                  ),
                  Text(
                    DateFormat.MMMd().format(date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewEntry() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DiaryEditorPage()));
  }

  void _openEntry(String entryId, Map<String, dynamic> data) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiaryReaderPage(entryId: entryId, data: data),
      ),
    );
  }

  void _editEntry(String entryId, Map<String, dynamic> data) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiaryEditorPage(entryId: entryId, initialData: data),
      ),
    );
  }

  void _deleteEntry(String entryId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Entry'),
            content: Text('Are you sure you want to delete "$title"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await LocalDataService.deleteData('entries', entryId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
      }
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
      default:
        return Icons.sentiment_neutral;
    }
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
      default:
        return Colors.grey;
    }
  }
}
