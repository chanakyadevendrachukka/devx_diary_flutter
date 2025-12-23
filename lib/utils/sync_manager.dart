import 'package:workmanager/workmanager.dart';
import 'local_data_service.dart';

/// Background sync manager using WorkManager
class SyncManager {
  static const String syncTaskName = 'dailyFirebaseSync';

  // Initialize background sync
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // Register periodic task (once per day)
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  // Manual sync trigger
  static Future<void> syncNow() async {
    if (await LocalDataService.needsSync()) {
      await LocalDataService.syncToFirebase();
    }
  }

  // Cancel all sync tasks
  static Future<void> cancelSync() async {
    await Workmanager().cancelAll();
  }
}

// Background callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == SyncManager.syncTaskName) {
        await LocalDataService.init();
        await LocalDataService.syncToFirebase();
      }
      return true;
    } catch (e) {
      return false;
    }
  });
}
