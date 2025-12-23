import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/local_data_service.dart';
import 'diary_editor_page.dart';

class DiaryReaderPage extends StatelessWidget {
  final String entryId;
  final Map<String, dynamic> data;

  const DiaryReaderPage({super.key, required this.entryId, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final content = data['content'] ?? '';
    final date =
        data['date'] != null ? DateTime.parse(data['date']) : DateTime.now();
    final mood = data['mood'] ?? 'neutral';
    final tags =
        (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getMoodColor(mood).withOpacity(0.6),
                      _getMoodColor(mood).withOpacity(0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getMoodIcon(mood),
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () => _editEntry(context),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share',
                onPressed: () => _shareEntry(),
              ),
              PopupMenuButton(
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteEntry(context);
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and mood info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getMoodColor(mood).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getMoodIcon(mood),
                          color: _getMoodColor(mood),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getMoodLabel(mood),
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getMoodColor(mood),
                              ),
                            ),
                            Text(
                              DateFormat.yMMMMd().add_jm().format(date),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          tags.map((tag) {
                            return Chip(
                              label: Text('#$tag'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              labelStyle: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  // Content
                  SelectableText(
                    content.isEmpty ? 'No content' : content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Updated at
                  if (data['updatedAt'] != null)
                    Center(
                      child: Text(
                        'Last updated: ${DateFormat.yMMMd().add_jm().format(DateTime.parse(data['updatedAt']))}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editEntry(context),
        icon: const Icon(Icons.edit),
        label: const Text('Edit'),
      ),
    );
  }

  void _editEntry(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiaryEditorPage(entryId: entryId, initialData: data),
      ),
    );
  }

  void _shareEntry() {
    final title = data['title'] ?? 'Untitled';
    final content = data['content'] ?? '';
    final date =
        data['date'] != null ? DateTime.parse(data['date']) : DateTime.now();
    final dateStr = DateFormat.yMMMMd().format(date);

    Share.share('$title\n$dateStr\n\n$content', subject: title);
  }

  void _deleteEntry(BuildContext context) async {
    final title = data['title'] ?? 'Untitled';
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
      if (context.mounted) {
        Navigator.pop(context);
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

  String _getMoodLabel(String mood) {
    switch (mood) {
      case 'happy':
        return 'Feeling Happy';
      case 'sad':
        return 'Feeling Sad';
      case 'angry':
        return 'Feeling Angry';
      case 'calm':
        return 'Feeling Calm';
      default:
        return 'Feeling Neutral';
    }
  }
}
