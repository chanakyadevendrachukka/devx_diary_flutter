import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-first data service that stores data in Hive and syncs to Firebase once daily
class LocalDataService {
  static const String _routinesBox = 'routines';
  static const String _entriesBox = 'entries';
  static const String _habitsBox = 'habits';
  static const String _peopleBox = 'people';
  static const String _remindersBox = 'reminders';
  static const String _vaultBox = 'vault';

  static const String _lastSyncKey = 'last_sync_timestamp';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_routinesBox);
    await Hive.openBox(_entriesBox);
    await Hive.openBox(_habitsBox);
    await Hive.openBox(_peopleBox);
    await Hive.openBox(_remindersBox);
    await Hive.openBox(_vaultBox);
  }

  // Check if sync is needed (once per day)
  static Future<bool> needsSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dayInMs = 24 * 60 * 60 * 1000;
    return (now - lastSync) > dayInMs;
  }

  // Mark sync as completed
  static Future<void> markSyncCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Sync all local data to Firebase
  static Future<void> syncToFirebase() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Sync routines
      await _syncBoxToFirebase(_routinesBox, uid, 'routines');

      // Sync entries
      await _syncBoxToFirebase(_entriesBox, uid, 'entries');

      // Sync habits
      await _syncBoxToFirebase(_habitsBox, uid, 'habits');

      // Sync people
      await _syncBoxToFirebase(_peopleBox, uid, 'people');

      // Sync reminders
      await _syncBoxToFirebase(_remindersBox, uid, 'reminders');

      await markSyncCompleted();
    } catch (e) {
      print('Sync error: $e');
    }
  }

  static Future<void> _syncBoxToFirebase(
    String boxName,
    String uid,
    String collection,
  ) async {
    final box = Hive.box(boxName);
    final firestore = FirebaseFirestore.instance;

    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null && data is Map) {
        final docId = key.toString();
        await firestore
            .collection('users')
            .doc(uid)
            .collection(collection)
            .doc(docId)
            .set(Map<String, dynamic>.from(data), SetOptions(merge: true));
      }
    }
  }

  // CRUD operations for routines with custom categories
  static Future<void> saveRoutine({
    required String date,
    required String category,
    required List<Map<String, dynamic>> tasks,
  }) async {
    final box = Hive.box(_routinesBox);
    final key = '${date}_$category';
    await box.put(key, {
      'date': date,
      'category': category,
      'tasks': tasks,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Map<String, dynamic>? getRoutine(String date, String category) {
    final box = Hive.box(_routinesBox);
    final key = '${date}_$category';
    final data = box.get(key);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static List<Map<String, dynamic>> getRoutinesForDate(String date) {
    final box = Hive.box(_routinesBox);
    final routines = <Map<String, dynamic>>[];

    for (var key in box.keys) {
      if (key.toString().startsWith(date)) {
        final data = box.get(key);
        if (data != null) {
          routines.add(Map<String, dynamic>.from(data));
        }
      }
    }

    return routines;
  }

  static Future<void> deleteRoutine(String date, String category) async {
    final box = Hive.box(_routinesBox);
    final key = '${date}_$category';
    await box.delete(key);
  }

  // Generic save for other collections
  static Future<void> saveData(
    String boxName,
    String key,
    Map<String, dynamic> data,
  ) async {
    final box = Hive.box(boxName);
    await box.put(key, data);
  }

  static dynamic getData(String boxName, String key) {
    final box = Hive.box(boxName);
    return box.get(key);
  }

  static Future<void> deleteData(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  static List<dynamic> getAllData(String boxName) {
    final box = Hive.box(boxName);
    return box.values.toList();
  }

  static Box getBox(String boxName) {
    return Hive.box(boxName);
  }
}
