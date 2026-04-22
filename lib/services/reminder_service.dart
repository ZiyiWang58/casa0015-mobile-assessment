import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles simple local notification setup and display.
class ReminderService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Initialize local notifications for Android.
  static Future<void> init() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(settings);
  }

  /// Request notification permission on Android if needed.
  static Future<void> requestPermission() async {
    final androidImplementation =
    notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  /// Show a simple reminder notification.
  static Future<void> showWalkReminder({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'walk_reminder_channel',
      'Walk Reminders',
      channelDescription: 'Reminders for daily dog walks',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }
}