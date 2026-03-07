import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service to manage local notifications.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;

    // Timezone initialization for scheduled notifications
    tz.initializeTimeZones();
    final String timeZoneName = tz.local.name;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == 'open_student_dashboard') {
          // Use navigator key to navigate when a notification is tapped.
          final navigator = navigatorKey.currentState;
          if (navigator != null) {
            navigator.pushNamedAndRemoveUntil(
              '/studentDashboardFromNotification',
              (route) => false,
            );
          }
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'General alerts and reminders',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  /// Show a simple instant notification.
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'General Notifications',
      channelDescription: 'General alerts and reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedule a daily reminder to remind students to check their timetable.
  ///
  /// For testing, the first notification is scheduled 2 minutes from now,
  /// and then repeats daily at the same time.
  Future<void> scheduleDailyTimetableReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = now.add(const Duration(minutes: 2));

    const androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'General Notifications',
      channelDescription: 'General alerts and reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Today\'s Classes',
      'Check your timetable and attendance for today.',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'open_student_dashboard',
    );
  }
}
