import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

abstract class IFirebaseAnalyticsService {
  Future<void> logLogin();
  Future<void> logSearchTopic(final String keyword);
  Future<void> logViewPublication(final String title, final int year);
  Future<void> logViewJournal(final String name);
  Future<void> logViewKeyword(final String keyword);
  Future<void> logExportPdf(final String topic);
  Future<void> logLogout();
}

@LazySingleton(as: IFirebaseAnalyticsService)
class FirebaseAnalyticsService implements IFirebaseAnalyticsService {
  FirebaseAnalyticsService() : _analytics = FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  Future<void> _safeLogEvent(final Future<void> Function() action) async {
    try {
      await action();
    } on Exception catch (e) {
      debugPrint('Firebase Analytics error (ignored): $e');
    }
  }

  @override
  Future<void> logLogin() async {
    await _safeLogEvent(() => _analytics.logLogin(loginMethod: 'google'));
  }

  @override
  Future<void> logSearchTopic(final String keyword) async {
    final Map<String, Object> params = <String, Object>{'keyword': keyword};
    await _safeLogEvent(
      () => _analytics.logEvent(name: 'search_topic', parameters: params),
    );
  }

  @override
  Future<void> logViewPublication(final String title, final int year) async {
    final Map<String, Object> params = <String, Object>{
      'title': title,
      'year': year,
    };
    await _safeLogEvent(
      () => _analytics.logEvent(name: 'view_publication', parameters: params),
    );
  }

  @override
  Future<void> logViewJournal(final String name) async {
    final Map<String, Object> params = <String, Object>{'name': name};
    await _safeLogEvent(
      () => _analytics.logEvent(name: 'view_journal', parameters: params),
    );
  }

  @override
  Future<void> logViewKeyword(final String keyword) async {
    final Map<String, Object> params = <String, Object>{'keyword': keyword};
    await _safeLogEvent(
      () => _analytics.logEvent(name: 'view_keyword', parameters: params),
    );
  }

  @override
  Future<void> logExportPdf(final String topic) async {
    final Map<String, Object> params = <String, Object>{'topic': topic};
    await _safeLogEvent(
      () => _analytics.logEvent(name: 'export_pdf', parameters: params),
    );
  }

  @override
  Future<void> logLogout() async {
    await _safeLogEvent(() => _analytics.logEvent(name: 'logout'));
  }
}
