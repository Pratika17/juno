import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../screens/chat/chat_detail_screen.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to initialize Firebase here, do it. But generally, the Flutter plugin
  // handles it if it's already initialized in main.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controller to handle notification taps if needed globally
  // Though typically we can handle them directly via callbacks

  Future<void> initNotifications() async {
    // 1. Request Permission (Crucial for iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Initialize Local Notifications (for Android Foreground)
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle when a local notification is tapped
        if (response.payload != null) {
          _handleNotificationTap(response.payload!);
        }
      },
    );

    // Create Android Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id from AndroidManifest
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 3. Setup Firebase Messaging Listeners
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message, channel);
      }
    });

    // Handle tap from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleRemoteMessageInteraction(message);
    });

    // Update FCM token if it changes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      // It's the responsibility of AuthProvider to save this to Firestore
      // when we have an active user, but it's good to broadcast or expose
      debugPrint('FCM Token refreshed: $newToken');
    });
  }

  void _showLocalNotification(
    RemoteMessage message,
    AndroidNotificationChannel channel,
  ) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      _navigateToRelevantScreen(data);
    } catch (e) {
      debugPrint("Error parsing notification payload: $e");
    }
  }

  void _handleRemoteMessageInteraction(RemoteMessage message) {
    _navigateToRelevantScreen(message.data);
  }

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from a terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null) {
      _handleRemoteMessageInteraction(initialMessage);
    }
  }

  void _navigateToRelevantScreen(Map<String, dynamic> data) {
    debugPrint("Navigate to: $data");

    final String? type = data['type'];
    final String? chatId = data['chatId'];

    if (type == 'new_message' && chatId != null) {
      final String otherUserId = data['senderId'] ?? '';
      final String otherUserName = data['senderName'] ?? 'User';

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        ),
      );
    }
  }

  // ---- Token Management ----

  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");
      return token;
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
      return null;
    }
  }

  Future<void> updateFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
    }
  }

  // ---- In-App Notifications (Firestore) ----

  // Creates a document in the recipient's subcollection or root collection
  // We'll use a root collection 'notifications' and filter by recipientId
  Future<void> createInAppNotification({
    required String recipientId,
    required String type, // 'new_message', 'item_status'
    required String title,
    required String body,
    String? chatId,
    String? itemId,
    String? senderId,
    String? senderName,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': recipientId,
        'type': type,
        'title': title,
        'body': body,
        'chatId': chatId,
        'itemId': itemId,
        'senderId': senderId,
        'senderName': senderName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error creating in-app notification: $e");
    }
  }

  Future<void> sendNewMessageNotification(
    String recipientId,
    String senderId,
    String senderName,
    String messagePreview,
    String chatId,
  ) async {
    await createInAppNotification(
      recipientId: recipientId,
      type: 'new_message',
      title: 'New message from $senderName',
      body: messagePreview,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
    );
  }

  Future<void> sendItemStatusNotification(
    String recipientId,
    String itemTitle,
    String newStatus,
    String itemId,
  ) async {
    await createInAppNotification(
      recipientId: recipientId,
      type: 'item_status',
      title: 'Item Update: $itemTitle',
      body: 'Status changed to $newStatus',
      itemId: itemId,
    );
  }
}
