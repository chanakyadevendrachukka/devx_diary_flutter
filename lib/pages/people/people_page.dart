import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../utils/local_data_service.dart';
import '../../utils/sync_manager.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

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

  Future<void> _addPerson() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final personId = const Uuid().v4();
    await LocalDataService.saveData('people', personId, {
      'id': personId,
      'name': name,
      'notes': _notesController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    _nameController.clear();
    _notesController.clear();
    if (mounted) Navigator.pop(context);
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
                                          Icons.person_add_alt,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Add Person',
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
                                        labelText: 'Name',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _notesController,
                                      minLines: 2,
                                      maxLines: 4,
                                      decoration: const InputDecoration(
                                        labelText: 'Notes',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: _addPerson,
                                        child: const Text('Add person'),
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
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Add person'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: LocalDataService.getBox('people').listenable(),
            builder: (context, Box box, _) {
              final people =
                  box.values
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();

              // Sort by creation date descending
              people.sort((a, b) {
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

              if (people.isEmpty) {
                return const Center(child: Text('No people yet'));
              }
              return ListView.separated(
                itemCount: people.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final person = people[index];
                  return ListTile(
                    title: Text(person['name'] ?? ''),
                    subtitle: Text(person['notes'] ?? ''),
                    onTap: () async {
                      // Show simple timeline: list entries tagged with person's name
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder:
                            (context) =>
                                _PersonTimeline(name: person['name'] ?? ''),
                      );
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
}

class _PersonTimeline extends StatelessWidget {
  final String name;
  const _PersonTimeline({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Timeline: $name',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ValueListenableBuilder(
              valueListenable: LocalDataService.getBox('entries').listenable(),
              builder: (context, Box box, _) {
                final allEntries =
                    box.values
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList();

                // Filter entries that have this person's name in tags
                final filteredEntries =
                    allEntries.where((entry) {
                      final tags =
                          (entry['tags'] as List?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [];
                      return tags.contains(name);
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
                    child: Text('No entries with this person yet.'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    final date =
                        entry['date'] != null
                            ? DateTime.parse(entry['date'])
                            : DateTime.now();
                    return ListTile(
                      title: Text(entry['title'] ?? '(untitled)'),
                      subtitle: Text(DateFormat.yMMMd().format(date)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
