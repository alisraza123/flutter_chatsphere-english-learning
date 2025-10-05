// firebase_api/firebase_api.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

// Single shared plugin instance (you can also make it inside class)
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Call this once on app startup (before scheduling)
  Future<void> initNotification() async {
    // initialize firebase if not already done (optional if done in main)
    await Firebase.initializeApp();

    // init timezone database and set local timezone to Pakistan
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    // If you want to detect device timezone dynamically, use flutter_timezone package
    // and set tz.setLocalLocation(tz.getLocation(deviceTzName));

    // request FCM permission (android: usually not required, but iOS needs it)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // init local notification plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings,
        // optional: handle tap
        );

    // create high-priority channel (only first creation matters)
    const channel = AndroidNotificationChannel(
      'daily_channel_id',
      'Daily Notifications',
      description: 'Daily notifications at scheduled time',
      importance: Importance.max,
      playSound: true,
      showBadge: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // optional: handle foreground FCM messages and show as local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title;
      final body = message.notification?.body;
      if (title != null || body != null) {
        _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_channel_id',
              'Daily Notifications',
              channelDescription: 'Daily notifications channel',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  /// Schedule a daily repeating local notification at [hour]:[minute] local (Pakistan tz)
  /// Use 24-hour hour (0..23). For 12:28 AM use hour:0, minute:28.
  Future<void> scheduleDailyAt({
    required int hour,
    required int minute,
    int id = 0,
    String title = 'ChatSphere Reminder',
    String body = 'Check ChatSphere for new messages!',
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // if time already passed today -> schedule for next day
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel_id',
          'Daily Notifications',
          channelDescription: 'Daily notifications channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      // required parameter in current plugin versions
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // set this to repeat daily at the same time
      matchDateTimeComponents: DateTimeComponents.time,
      // payload optional
      payload: 'daily_reminder',
    );

    // debug log
    print('Scheduled daily notification at ${scheduled.toLocal()}');
  }

  /// Cancel scheduled notification by id (if you want)
  Future<void> cancelScheduled(int id) async {
    await _localNotifications.cancel(id);
  }
}
