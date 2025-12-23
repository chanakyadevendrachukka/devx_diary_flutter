import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../services/notification_service.dart';
import '../../utils/local_data_service.dart';
import '../../utils/sync_manager.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _dateTime = DateTime.now().add(const Duration(hours: 1));

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

  Future<void> _addReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final reminderId = const Uuid().v4();
    final reminderData = {
      'id': reminderId,
      'title': title,
      'description': _descController.text.trim(),
      'scheduledAt': _dateTime.toIso8601String(),
      'status': 'scheduled',
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await LocalDataService.saveData('reminders', reminderId, reminderData);

      // Schedule Android alarm notification with custom name
      await NotificationService.scheduleReminder(
        id: reminderId,
        title: title,
        description: _descController.text.trim(),
        scheduledTime: _dateTime,
      );

      // Still call Firebase Function for email scheduling (optional)
      try {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'scheduleEmailReminder',
        );
        await callable.call({
          'reminderId': reminderId,
          'title': title,
          'description': _descController.text.trim(),
          'scheduledAt': _dateTime.toIso8601String(),
        });
      } catch (e) {
        // Silently ignore; backend may not be set up yet.
        print('Firebase function call skipped: $e');
      }

      _titleController.clear();
      _descController.clear();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder scheduled: $title'),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error adding reminder: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling reminder: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteReminder(String id) async {
    await NotificationService.cancelReminder(id);
    await LocalDataService.deleteData('reminders', id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder:
                      (context) => SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                            left: 16,
                            right: 16,
                            top: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _descController,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _dateTime,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date == null) return;
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      _dateTime,
                                    ),
                                  );
                                  if (time == null) return;
                                  setState(
                                    () =>
                                        _dateTime = DateTime(
                                          date.year,
                                          date.month,
                                          date.day,
                                          time.hour,
                                          time.minute,
                                        ),
                                  );
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date & time',
                                  ),
                                  child: Text(
                                    DateFormat.yMMMd().add_jm().format(
                                      _dateTime,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _addReminder,
                                  child: const Text('Schedule reminder alarm'),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                );
              },
              icon: const Icon(Icons.alarm_add),
              label: const Text('New reminder'),
            ),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: LocalDataService.getBox('reminders').listenable(),
            builder: (context, Box box, _) {
              // Check if box is open
              if (!box.isOpen) {
                return const Center(child: Text('Loading reminders...'));
              }

              final reminders =
                  box.values
                      .map((e) {
                        try {
                          return Map<String, dynamic>.from(e as Map);
                        } catch (e) {
                          return null;
                        }
                      })
                      .whereType<Map<String, dynamic>>()
                      .toList();

              // Sort by scheduled date
              reminders.sort((a, b) {
                try {
                  final dateA =
                      a['scheduledAt'] != null
                          ? DateTime.parse(a['scheduledAt'])
                          : DateTime.now();
                  final dateB =
                      b['scheduledAt'] != null
                          ? DateTime.parse(b['scheduledAt'])
                          : DateTime.now();
                  return dateA.compareTo(dateB);
                } catch (e) {
                  return 0;
                }
              });

              if (reminders.isEmpty) {
                return const Center(child: Text('No reminders'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];

                  // Safety check
                  if (reminder['id'] == null) {
                    return const SizedBox.shrink();
                  }

                  final when =
                      reminder['scheduledAt'] != null
                          ? DateTime.tryParse(reminder['scheduledAt']) ??
                              DateTime.now()
                          : DateTime.now();
                  final status = reminder['status'] ?? 'scheduled';
                  final isPast = when.isBefore(DateTime.now());

                  return Dismissible(
                    key: Key(reminder['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _deleteReminder(reminder['id']);
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isPast
                              ? Icons.schedule_outlined
                              : Icons.notifications_active,
                          color:
                              isPast
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          reminder['title'] ?? '(untitled)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isPast ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reminder['description'] != null &&
                                reminder['description'].toString().isNotEmpty)
                              Text(
                                reminder['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat.yMMMd().add_jm().format(when)} • $status',
                              style: TextStyle(
                                fontSize: 12,
                                color: isPast ? Colors.grey : null,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: const Text('Delete Reminder'),
                                    content: const Text(
                                      'Are you sure you want to delete this reminder?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _deleteReminder(reminder['id']);
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
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
