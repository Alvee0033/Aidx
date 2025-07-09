import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'medigay_channel';

  Future<void> init() async {
    // Configure local timezone (required for scheduled notifications)
    tz.initializeTimeZones();
    // Use device's local timezone without relying on external plugin

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
    debugPrint('✅ Local notification service initialized');
  }

  // Build generic notification details
  NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      'MediGay Notifications',
      channelDescription: 'General notifications for MediGay app',
      importance: Importance.high,
      priority: Priority.high,
    );

    return const NotificationDetails(android: androidDetails);
  }

  Future<void> _ensurePermissions() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  // Show an immediate notification
  Future<void> showNotification({
    required String title, 
    required String body,
  }) async {
    try {
      await _ensurePermissions();
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        _notificationDetails(),
      );
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  // Schedule a one-time notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      await _ensurePermissions();
      final int id = scheduledTime.millisecondsSinceEpoch.remainder(100000);
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        _notificationDetails(),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> showNewsNotification({
    required String title,
    required String body,
  }) async {
    await showNotification(title: title, body: body);
  }
} 