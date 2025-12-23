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
  DateTime _date = DateTime.now();
  String _mood = 'neutral';
  final List<String> _tags = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      _titleController.text = data['title'] ?? '';
      _contentController.text = data['content'] ?? '';
      _mood = data['mood'] ?? 'neutral';
      _date =
          data['date'] != null ? DateTime.parse(data['date']) : DateTime.now();
      _tags.addAll((data['tags'] as List?)?.map((e) => e.toString()) ?? []);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final entryId = widget.entryId ?? const Uuid().v4();
    final payload = {
      'id': entryId,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'mood': _mood,
      'tags': _tags,
      'date': _date.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    try {
      await LocalDataService.saveData('entries', entryId, payload);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryId == null ? 'New Entry' : 'Edit Entry'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date'),
                        child: Text(DateFormat.yMMMd().format(_date)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _mood,
                      decoration: const InputDecoration(labelText: 'Mood'),
                      items: const [
                        DropdownMenuItem(value: 'happy', child: Text('Happy')),
                        DropdownMenuItem(value: 'sad', child: Text('Sad')),
                        DropdownMenuItem(value: 'angry', child: Text('Angry')),
                        DropdownMenuItem(value: 'calm', child: Text('Calm')),
                        DropdownMenuItem(
                          value: 'neutral',
                          child: Text('Neutral'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _mood = v ?? 'neutral'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in _tags)
                    Chip(
                      label: Text(tag),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Add tag',
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        final t = v.trim();
                        if (t.isNotEmpty) setState(() => _tags.add(t));
                        _tagController.clear();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
