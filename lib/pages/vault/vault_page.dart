import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/ui_helpers.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  final _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final jsonStr = await _storage.read(key: 'vault_items');
    final list =
        jsonStr != null
            ? List<Map<String, dynamic>>.from(json.decode(jsonStr))
            : <Map<String, dynamic>>[];
    setState(() => _items = list);
  }

  Future<void> _save() async {
    await _storage.write(key: 'vault_items', value: json.encode(_items));
  }

  Future<void> _addOrEdit({int? index}) async {
    final nameController = TextEditingController(
      text: index != null ? _items[index]['name'] ?? '' : '',
    );
    final userController = TextEditingController(
      text: index != null ? _items[index]['username'] ?? '' : '',
    );
    final passController = TextEditingController(
      text: index != null ? _items[index]['password'] ?? '' : '',
    );
    final notesController = TextEditingController(
      text: index != null ? _items[index]['notes'] ?? '' : '',
    );
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
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
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Website/App'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: userController,
                  decoration: const InputDecoration(
                    labelText: 'Username/Email',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passController,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final item = {
                        'name': nameController.text.trim(),
                        'username': userController.text.trim(),
                        'password': passController.text.trim(),
                        'notes': notesController.text.trim(),
                      };
                      if (index == null) {
                        _items.add(item);
                      } else {
                        _items[index] = item;
                      }
                      await _save();
                      if (context.mounted) Navigator.pop(context);
                      setState(() {});
                    },
                    child: Text(index == null ? 'Add' : 'Save'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
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
              onPressed: () => _addOrEdit(),
              icon: const Icon(Icons.add),
              label: const Text('Add credential'),
            ),
          ),
        ),
        Expanded(
          child:
              _items.isEmpty
                  ? const Center(child: Text('No credentials. Tap + to add.'))
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return UIHelpers.customListTile(
                        context: context,
                        leading: Icons.lock_outline,
                        title: item['name'] ?? '(untitled)',
                        subtitle: item['username'] ?? '',
                        trailingIcon: Icons.edit,
                        onTap: () => _addOrEdit(index: index),
                        onTrailing: () => _addOrEdit(index: index),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
