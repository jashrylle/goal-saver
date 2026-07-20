import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Callback type for when a notification is tapped.
/// Returns the payload string (e.g. "goal_id" or "add_savings").
typedef NotificationTapCallback = void Function(String? payload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Callback invoked when user taps on a notification.
  NotificationTapCallback? onNotificationTap;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Queue for notification taps that arrive before the app is fully ready.
  static String? _pendingNotificationPayload;

  /// Store a notification payload for later consumption by [GoalSaverShell].
  static void storePendingPayload(String? payload) {
    _pendingNotificationPayload = payload;
  }

  /// Returns and clears any pending notification payload.
  static String? consumePendingPayload() {
    final payload = _pendingNotificationPayload;
    _pendingNotificationPayload = null;
    return payload;
  }

  Future<void> initialize({NotificationTapCallback? onTap}) async {
    onNotificationTap = onTap;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Handle notification tap — parse payload and route accordingly.
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    
    // If a custom callback is set, use it
    if (onNotificationTap != null) {
      onNotificationTap!(payload);
      return;
    }

    // If no callback, store the payload for later consumption by GoalSaverShell
    if (payload != null && payload.isNotEmpty) {
      storePendingPayload(payload);
    }
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'goal_saver_channel',
      'Goal Saver Notifications',
      channelDescription: 'Notifications for savings goals and reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: 'notification_$id',
    );
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'goal_saver_channel',
      'Goal Saver Notifications',
      channelDescription: 'Daily reminders for savings goals',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder_$id',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Schedule a recurring notification aligned to the goal's frequency.
  ///
  /// For daily goals: repeats daily at [hour]:[minute].
  /// For weekly goals: repeats weekly on the chosen weekday.
  /// For monthly goals: repeats monthly on the chosen day.
  /// Uses platform-level scheduling to fire even when the app is in the background.
  Future<void> scheduleFrequencyAware({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int frequencyDays,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'goal_saver_channel',
      'Goal Saver Notifications',
      channelDescription: 'Per-goal reminders for savings goals',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Choose the right repeat component based on frequency:
    // - Daily (1 day): repeat at the same time each day
    // - Weekly (7 days): repeat on the same day-of-week at the same time
    // - Bi-weekly (14 days): repeat every 14 days at the same time
    // - Monthly (30+ days): repeat on the same day-of-month at the same time
    final DateTimeComponents repeatComponent;
    if (frequencyDays <= 1) {
      repeatComponent = DateTimeComponents.time;
    } else if (frequencyDays <= 7) {
      repeatComponent = DateTimeComponents.dayOfWeekAndTime;
    } else {
      repeatComponent = DateTimeComponents.dayOfMonthAndTime;
    }

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: repeatComponent,
      payload: 'goal_reminder_$id',
    );
  }

  /// Schedule a one-off notification after a delay.
  Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    int delayMinutes = 30,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'goal_saver_alerts',
      'Goal Saver Alerts',
      channelDescription: 'Important alerts for savings goals',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: delayMinutes));

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'alert_$id',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}