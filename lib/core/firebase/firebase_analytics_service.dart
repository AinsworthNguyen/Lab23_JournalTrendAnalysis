import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

abstract class IFirebaseAnalyticsService {
  Future<void> logLogin();
  Future<void> logSearchTopic(String keyword);
  Future<void> logViewPublication(String title, int year);
  Future<void> logViewJournal(String name);
  Future<void> logViewKeyword(String keyword);
  Future<void> logExportPdf(String topic);
  Future<void> logLogout();
}

@LazySingleton(as: IFirebaseAnalyticsService)
class FirebaseAnalyticsService implements IFirebaseAnalyticsService {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsService() : _analytics = FirebaseAnalytics.instance;

  Future<void> _safeLogEvent(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Firebase Analytics error (ignored): $e');
    }
  }

  @override
  Future<void> logLogin() async {
    await _safeLogEvent(() => _analytics.logLogin(loginMethod: 'google'));
  }

  @override
  Future<void> logSearchTopic(String keyword) async {
    await _safeLogEvent(() => _analytics.logEvent(
      name: 'search_topic',
      parameters: {'keyword': keyword},
    ));
  }

  @override
  Future<void> logViewPublication(String title, int year) async {
    await _safeLogEvent(() => _analytics.logEvent(
      name: 'view_publication',
      parameters: {
        'title': title,
        'year': year,
      },
    ));
  }

  @override
  Future<void> logViewJournal(String name) async {
    await _safeLogEvent(() => _analytics.logEvent(
      name: 'view_journal',
      parameters: {'name': name},
    ));
  }

  @override
  Future<void> logViewKeyword(String keyword) async {
    await _safeLogEvent(() => _analytics.logEvent(
      name: 'view_keyword',
      parameters: {'keyword': keyword},
    ));
  }

  @override
  Future<void> logExportPdf(String topic) async {
    await _safeLogEvent(() => _analytics.logEvent(
      name: 'export_pdf',
      parameters: {'topic': topic},
    ));
  }

  @override
  Future<void> logLogout() async {
    await _safeLogEvent(() => _analytics.logEvent(name: 'logout'));
  }
}
