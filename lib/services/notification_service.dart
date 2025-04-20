import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get and save FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // Handle token refresh
      _messaging.onTokenRefresh.listen(_saveFCMToken);
    } catch (e) {
      // Handle error silently in production
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Handle error silently in production
    }
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken != null) {
        await _messaging.sendMessage(
          to: fcmToken,
          data: {
            'title': title,
            'body': body,
            ...?data,
          },
        );
      }
    } catch (e) {
      // Handle error silently in production
    }
  }

  void _handleMessage(RemoteMessage message) {
    // Handle the message appropriately
    final data = message.data;
    final notification = message.notification;
    
    if (notification != null) {
      // Handle notification
    }
    
    if (data.isNotEmpty) {
      // Handle data payload
    }
  }

  // Handle notification when the app is opened from a terminated state
  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      _handleMessage(message);
    }
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    _handleMessage(message);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
} 