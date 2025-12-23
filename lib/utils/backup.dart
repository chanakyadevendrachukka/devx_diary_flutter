import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupUtils {
  static Future<String> exportAll() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fs = FirebaseFirestore.instance;
    final storage = const FlutterSecureStorage();

    Future<List<Map<String, dynamic>>> collectAllDocs(String name) async {
      final snap = await fs.collection('users').doc(uid).collection(name).get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    }

    final entries = await collectAllDocs('entries');
    final habits = await collectAllDocs('habits');
    final routines = await collectAllDocs('routines');
    final people = await collectAllDocs('people');
    final reminders = await collectAllDocs('reminders');
    final vaultStr = await storage.read(key: 'vault_items');
    final vault = vaultStr != null ? json.decode(vaultStr) : [];

    final payload = {
      'createdAt': DateTime.now().toIso8601String(),
      'entries': entries,
      'habits': habits,
      'routines': routines,
      'people': people,
      'reminders': reminders,
      'vault': vault,
    };

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/devx_diary_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(json.encode(payload));

    await Share.shareXFiles([XFile(file.path)], text: 'DevX Diary backup');
    return file.path;
  }

  static Future<int> importAll() async {
    // For MVP, this is a stub that would read a file picker input and import data.
    // Implementation requires UI to select a file; you can implement using file_picker.
    // Returning 0 for now.
    return 0;
  }
}
