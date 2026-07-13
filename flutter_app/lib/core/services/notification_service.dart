import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  final DateTime _lastListenTime = DateTime.now();

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialization Settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialization Settings for iOS
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // Request permissions for Android 13+
    _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    _isInitialized = true;
    _listenToFirestore();
  }

  void _listenToFirestore() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) return;

      FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(1) // Only listen for new ones
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isEmpty) return;
        
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            final createdAt = data?['createdAt'] as Timestamp?;
            
            // Only show local notification if it was created AFTER we started listening
            if (createdAt != null && createdAt.toDate().isAfter(_lastListenTime)) {
              final targetUserId = data?['targetUserId'];
              
              // If it's a global notification ('all') or targeted specifically to this user
              if (targetUserId == 'all' || targetUserId == user.uid) {
                _showLocalNotification(
                  id: change.doc.hashCode,
                  title: data?['title'] ?? 'New Notification',
                  body: data?['body'] ?? '',
                );
              }
            }
          }
        }
      });
    });
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_sound_channel_v3', // New ID to ensure a fresh, working channel
      'Default Sound Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> showWelcomeNotification({required String userName}) async {
    await _showLocalNotification(
      id: 9999, // Unique ID for welcome notification
      title: 'Welcome to Forge! 🎉',
      body: 'Hello $userName, ready to start learning? Tap to view your dashboard.',
    );
  }
}

final notificationService = NotificationService();
