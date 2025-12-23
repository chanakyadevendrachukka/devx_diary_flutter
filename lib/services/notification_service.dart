import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String reminderChannelId = 'reminder_channel';
  static const String reminderChannelName = 'Reminders';
  static const String reminderChannelDescription =
      'Notifications for scheduled reminders';

  /// Initialize the notification service
  static Future<void> initialize() async {
    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      // Set local location - fallback to UTC if not available
      final locationName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      // If timezone initialization fails, continue anyway
      print('Timezone initialization warning: $e');
    }

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    // Initialize Workmanager
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    } catch (e) {
      print('Workmanager initialization warning: $e');
    }
  }

  /// Create Android notification channel
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      reminderChannelId,
      reminderChannelName,
      description: reminderChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation when notification is tapped
    // You can add navigation logic here if needed
  }

  /// Schedule a reminder notification
  static Future<void> scheduleReminder({
    required String id,
    required String title,
    required String description,
    required DateTime scheduledTime,
  }) async {
    try {
      // Calculate delay until scheduled time
      final now = DateTime.now();
      final delay = scheduledTime.difference(now);

      if (delay.isNegative) {
        // If time is in the past, don't schedule
        print('Cannot schedule reminder in the past');
        return;
      }

      // Use unique integer ID from string ID (hash code)
      final notificationId = id.hashCode.abs() % 2147483647;

      // Create TZDateTime for the scheduled time
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Schedule using timezone
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        description.isEmpty ? 'Reminder notification' : description,
        tzScheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            reminderChannelId,
            reminderChannelName,
            channelDescription: reminderChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            styleInformation: BigTextStyleInformation(
              description.isEmpty ? 'Reminder notification' : description,
              contentTitle: title,
              summaryText: 'DevX Diary Reminder',
            ),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: id,
      );

      print('Notification scheduled successfully for $scheduledTime');

      // Also schedule a workmanager task as backup
      try {
        await Workmanager().registerOneOffTask(
          'reminder_$id',
          'reminderTask',
          initialDelay: delay,
          inputData: {'id': id, 'title': title, 'description': description},
          constraints: Constraints(networkType: NetworkType.not_required),
        );
      } catch (e) {
        print('Workmanager scheduling warning: $e');
      }
    } catch (e, stackTrace) {
      print('Error scheduling reminder: $e');
      print('Stack trace: $stackTrace');
      // Don't throw error - allow the app to continue
    }
  }

  /// Cancel a scheduled reminder
  static Future<void> cancelReminder(String id) async {
    final notificationId = id.hashCode.abs() % 2147483647;
    await _notificationsPlugin.cancel(notificationId);
    await Workmanager().cancelByUniqueName('reminder_$id');
  }

  /// Show immediate notification
  static Future<void> showNotification({
    required String id,
    required String title,
    required String description,
  }) async {
    final notificationId = id.hashCode.abs() % 2147483647;

    await _notificationsPlugin.show(
      notificationId,
      title,
      description.isEmpty ? 'Reminder notification' : description,
      NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          reminderChannelName,
          channelDescription: reminderChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            description.isEmpty ? 'Reminder notification' : description,
            contentTitle: title,
            summaryText: 'DevX Diary Reminder',
          ),
        ),
      ),
      payload: id,
    );
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    await Workmanager().cancelAll();
  }

  /// Request notification permissions (Android 13+)
  static Future<bool> requestPermissions() async {
    final androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      final granted =
          await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }
}

/// Workmanager callback for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'reminderTask') {
      // Show notification when task executes
      await NotificationService.showNotification(
        id: inputData?['id'] ?? '',
        title: inputData?['title'] ?? 'Reminder',
        description: inputData?['description'] ?? '',
      );
    }
    return Future.value(true);
  });
}
