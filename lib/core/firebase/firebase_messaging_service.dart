import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

abstract class IFirebaseMessagingService {
  Future<void> initialize();
  Future<String?> getFcmToken();
  Stream<RemoteMessage> get onMessageReceived;
}

@LazySingleton(as: IFirebaseMessagingService)
class FirebaseMessagingService implements IFirebaseMessagingService {
  FirebaseMessagingService() : _fcm = FirebaseMessaging.instance;

  final FirebaseMessaging _fcm;
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  @override
  Future<void> initialize() async {
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
    } on Exception catch (e) {
      debugPrint('[WARNING] FCM requestPermission failed: $e');
    }

    FirebaseMessaging.onMessage.listen(_messageStreamController.add);

    _fcm.onTokenRefresh.listen((final String newToken) async {
      await _saveTokenToFirestore(newToken);
    });

    // Listen to authentication state changes to dynamically save token under the active user
    FirebaseAuth.instance.authStateChanges().listen((final User? user) async {
      try {
        final String? token = await _fcm.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }
      } on Exception catch (e) {
        debugPrint('[WARNING] FCM getToken failed: $e');
      }
    });
  }

  @override
  Future<String?> getFcmToken() async {
    try {
      final String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
      return token;
    } on Exception catch (_) {
      return null;
    }
  }

  Future<void> _saveTokenToFirestore(final String token) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final String userId = user?.uid ?? 'anonymous_guest';

      final Map<String, dynamic> tokenData = <String, dynamic>{
        'token': token,
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(token)
          .set(tokenData);
      debugPrint(
        '[INFO] FCM Token successfully saved to Firestore for user: $userId',
      );
    } on Exception catch (e) {
      debugPrint('[WARNING] Failed to save FCM Token to Firestore: $e');
    }
  }

  @override
  Stream<RemoteMessage> get onMessageReceived =>
      _messageStreamController.stream;
}
