import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../utils/local_data_service.dart';

class DiaryEditorPage extends StatefulWidget {
  final String? entryId;
  final Map<String, dynamic>? initialData;
  const DiaryEditorPage({super.key, this.entryId, this.initialData});

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _mood = 'neutral';
  final List<String> _tags = [];
  bool _saving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      _titleController.text = data['title'] ?? '';
      _contentController.text = data['content'] ?? '';
      _mood = data['mood'] ?? 'neutral';
      if (data['date'] != null) {
        final dateTime = DateTime.parse(data['date']);
        _date = dateTime;
        _time = TimeOfDay.fromDateTime(dateTime);
      }
      _tags.addAll((data['tags'] as List?)?.map((e) => e.toString()) ?? []);
    }

    _titleController.addListener(_markUnsaved);
    _contentController.addListener(_markUnsaved);
  }

  void _markUnsaved() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to leave?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Discard'),
              ),
            ],
          ),
    );

    return shouldPop ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final entryId = widget.entryId ?? const Uuid().v4();
    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final payload = {
      'id': entryId,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'mood': _mood,
      'tags': _tags,
      'date': dateTime.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await LocalDataService.saveData('entries', entryId, payload);
      _hasUnsavedChanges = false;
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entryId == null ? 'New Entry' : 'Edit Entry'),
          actions: [
            if (_hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    'Unsaved',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            IconButton(
              onPressed: _saving ? null : _save,
              icon:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check),
              tooltip: 'Save',
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Entry title',
                    border: InputBorder.none,
                    hintStyle: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  validator:
                      (v) =>
                          v?.trim().isEmpty == true
                              ? 'Title is required'
                              : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const Divider(),
                const SizedBox(height: 16),
                // Date and Time
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              _date = picked;
                              _markUnsaved();
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat.yMMMd().format(_date)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _time,
                          );
                          if (picked != null) {
                            setState(() {
                              _time = picked;
                              _markUnsaved();
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(_time.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Mood selector
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMoodChip(
                      'happy',
                      'Happy',
                      Icons.sentiment_very_satisfied,
                      Colors.amber,
                    ),
                    _buildMoodChip(
                      'calm',
                      'Calm',
                      Icons.self_improvement,
                      Colors.green,
                    ),
                    _buildMoodChip(
                      'neutral',
                      'Neutral',
                      Icons.sentiment_neutral,
                      Colors.grey,
                    ),
                    _buildMoodChip(
                      'sad',
                      'Sad',
                      Icons.sentiment_dissatisfied,
                      Colors.blue,
                    ),
                    _buildMoodChip(
                      'angry',
                      'Angry',
                      Icons.sentiment_very_dissatisfied,
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Content
                TextFormField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: 10,
                  style: const TextStyle(fontSize: 16, height: 1.8),
                  decoration: const InputDecoration(
                    hintText: 'Write your thoughts here...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 16),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                // Character count
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_contentController.text.length} characters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                // Tags
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in _tags)
                      Chip(
                        label: Text('#$tag'),
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                            _markUnsaved();
                          });
                        },
                        deleteIcon: const Icon(Icons.close, size: 18),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Add tag'),
                      onPressed: () => _showAddTagDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child:
                        _saving
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Save Entry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChip(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _mood == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _mood = value;
          _markUnsaved();
        });
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: isSelected ? Colors.white : color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      showCheckmark: false,
      backgroundColor: color.withOpacity(0.08),
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color.withOpacity(0.4)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Add Tag'),
          content: TextField(
            controller: _tagController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter tag name',
              prefixText: '#',
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) {
              _addTag();
              Navigator.pop(dialogCtx);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addTag();
                Navigator.pop(dialogCtx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _markUnsaved();
      });
      _tagController.clear();
    }
  }
}
