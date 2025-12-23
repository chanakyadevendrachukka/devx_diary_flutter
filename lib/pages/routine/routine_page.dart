import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/local_data_service.dart';
import '../../utils/sync_manager.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  DateTime _date = DateTime.now();
  String _selectedCategory = 'Morning';
  final _taskController = TextEditingController();
  final _categoryController = TextEditingController();
  
  // Default categories
  final List<String> _defaultCategories = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
    'Workout',
    'Work',
  ];
  
  List<String> _customCategories = [];
  List<String> get _allCategories => [..._defaultCategories, ..._customCategories];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
    _checkAndSync();
  }

  Future<void> _checkAndSync() async {
    if (await LocalDataService.needsSync()) {
      await SyncManager.syncNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data synced to cloud')),
        );
      }
    }
  }

  Future<void> _loadCustomCategories() async {
    final data = LocalDataService.getData('routines', 'custom_categories');
    if (data != null && data is List) {
      setState(() {
        _customCategories = List<String>.from(data);
      });
    }
  }

  Future<void> _addCustomCategory() async {
    final category = _categoryController.text.trim();
    if (category.isEmpty || _allCategories.contains(category)) return;
    
    setState(() {
      _customCategories.add(category);
    });
    
    await LocalDataService.saveData(
      'routines',
      'custom_categories',
      {'categories': _customCategories},
    );
    
    _categoryController.clear();
    if (mounted) Navigator.pop(context);
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _addTask() async {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;
    
    final routine = LocalDataService.getRoutine(_dateKey, _selectedCategory);
    final tasks = List<Map<String, dynamic>>.from(routine?['tasks'] ?? []);
    
    tasks.add({'title': text, 'done': false});
    
    await LocalDataService.saveRoutine(
      date: _dateKey,
      category: _selectedCategory,
      tasks: tasks,
    );
    
    _taskController.clear();
    setState(() {});
  }

  Future<void> _toggleTask(Map<String, dynamic> task) async {
    final routine = LocalDataService.getRoutine(_dateKey, _selectedCategory);
    final tasks = List<Map<String, dynamic>>.from(routine?['tasks'] ?? []);
    
    final index = tasks.indexWhere((t) => t['title'] == task['title']);
    if (index != -1) {
      tasks[index]['done'] = !(tasks[index]['done'] == true);
      
      await LocalDataService.saveRoutine(
        date: _dateKey,
        category: _selectedCategory,
        tasks: tasks,
      );
      
      setState(() {});
    }
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final routine = LocalDataService.getRoutine(_dateKey, _selectedCategory);
    final tasks = List<Map<String, dynamic>>.from(routine?['tasks'] ?? []);
    
    tasks.removeWhere((t) => t['title'] == task['title']);
    
    await LocalDataService.saveRoutine(
      date: _dateKey,
      category: _selectedCategory,
      tasks: tasks,
    );
    
    setState(() {});
  }

  Future<void> _reusePreviousDay() async {
    final prev = _date.subtract(const Duration(days: 1));
    final prevKey = DateFormat('yyyy-MM-dd').format(prev);
    final routine = LocalDataService.getRoutine(prevKey, _selectedCategory);
    
    if (routine != null) {
      final tasks = List<Map<String, dynamic>>.from(routine['tasks'] ?? []);
      final resetTasks = tasks.map((t) => {
        'title': t['title'],
        'done': false,
      }).toList();
      
      await LocalDataService.saveRoutine(
        date: _dateKey,
        category: _selectedCategory,
        tasks: resetTasks,
      );
      
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final routine = LocalDataService.getRoutine(_dateKey, _selectedCategory);
    final tasks = List<Map<String, dynamic>>.from(routine?['tasks'] ?? []);

    return Column(
      children: [
        // Date & Sync Status
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
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
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          isDense: true,
                        ),
                        child: Text(DateFormat.yMMMd().format(_date)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Sync now',
                    onPressed: () async {
                      await SyncManager.syncNow();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Synced!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.cloud_upload),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _reusePreviousDay,
                      child: const Text('Reuse previous day'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Category tabs
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final category in _allCategories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  ),
                ),
              // Add category button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: const Icon(Icons.add, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add Custom Category'),
                        content: TextField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category name',
                          ),
                          autofocus: true,
                          onSubmitted: (_) => _addCustomCategory(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: _addCustomCategory,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Task input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    hintText: 'Add task to $_selectedCategory',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              IconButton(
                onPressed: _addTask,
                icon: const Icon(Icons.add_task),
              ),
            ],
          ),
        ),
        
        // Tasks list
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    'No tasks for $_selectedCategory',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        title: Text(
                          task['title'] ?? '',
                          style: TextStyle(
                            decoration: task['done'] == true
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        value: task['done'] == true,
                        onChanged: (_) => _toggleTask(task),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteTask(task),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
