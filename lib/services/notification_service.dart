import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? token = await _messaging.getToken();
        debugPrint('FCM Token: $token');

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          debugPrint('Message data: ${message.data}');
        });

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Get FCM token and save it to Firestore
  Future<void> saveFCMToken(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
        });
        print('FCM Token saved successfully');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Send a notification to a specific user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get the user's FCM token
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      String? fcmToken = userDoc.get('fcmToken');

      if (fcmToken != null) {
        // Create the notification message
        final message = {
          'to': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        };

        // Save the notification to Firestore
        await _firestore.collection('notifications').add({
          ...message,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        print('Notification sent successfully');
      } else {
        print('No FCM token found for user');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Handle notification when the app is opened from a terminated state
  void handleInitialMessage() {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state with notification');
        print('Message data: ${message.data}');
      }
    });
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
} 