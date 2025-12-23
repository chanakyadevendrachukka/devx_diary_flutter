import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  DateTime _date = DateTime.now();
  final _taskController = TextEditingController();

  DocumentReference<Map<String, dynamic>> _docRef(String uid) {
    final key = DateFormat('yyyy-MM-dd').format(_date);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('routines')
        .doc(key);
  }

  Future<void> _addTask() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final text = _taskController.text.trim();
    if (text.isEmpty) return;
    await _docRef(uid).set({
      'tasks': FieldValue.arrayUnion([
        {'title': text, 'done': false},
      ]),
    }, SetOptions(merge: true));
    _taskController.clear();
  }

  Future<void> _toggleTask(Map<String, dynamic> task) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final updated = {'title': task['title'], 'done': !(task['done'] == true)};
    final doc = await _docRef(uid).get();
    final tasks = List<Map<String, dynamic>>.from(doc.data()?['tasks'] ?? []);
    final newTasks =
        tasks.map((t) => t['title'] == task['title'] ? updated : t).toList();
    await _docRef(uid).set({'tasks': newTasks});
  }

  Future<void> _reusePreviousDay() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final prev = _date.subtract(const Duration(days: 1));
    final prevKey = DateFormat('yyyy-MM-dd').format(prev);
    final prevDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('routines')
            .doc(prevKey)
            .get();
    final tasks = List<Map<String, dynamic>>.from(
      prevDoc.data()?['tasks'] ?? [],
    );
    await _docRef(uid).set({
      'tasks': tasks.map((t) => {'title': t['title'], 'done': false}).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _reusePreviousDay,
                child: const Text('Reuse previous day'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(hintText: 'Add task'),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              IconButton(onPressed: _addTask, icon: const Icon(Icons.add_task)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _docRef(uid).snapshots(),
            builder: (context, snapshot) {
              final tasks = List<Map<String, dynamic>>.from(
                snapshot.data?.data()?['tasks'] ?? [],
              );
              if (tasks.isEmpty) {
                return const Center(child: Text('No tasks for this day'));
              }
              return ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final t = tasks[index];
                  return CheckboxListTile(
                    title: Text(t['title'] ?? ''),
                    value: t['done'] == true,
                    onChanged: (_) => _toggleTask(t),
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
