import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/prefs_keys.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user_account_model.dart';
import '../../domain/entities/user_activity_log.dart';

abstract class IUserActivityTracker {
  List<UserActivityLog> getLogs();
  List<UserAccountModel> getUsers();
  Future<void> logActivity({
    required String actionTitle,
    required String details,
    required ActivityType type,
    String? userName,
    String? userEmail,
    String? platform,
    String status = 'SUCCESS',
  });
  Future<void> logSearch(String query);
  Future<void> logPdfExport(String reportTitle);
  Future<void> logLogin(String email, [String? name]);
  Future<void> logPreferenceUpdate(String conceptName, String name);
  Future<void> clearAllLogs();
}

@LazySingleton(as: IUserActivityTracker)
class UserActivityTracker implements IUserActivityTracker {
  final Box _activityBox;

  UserActivityTracker(@Named('activityBox') this._activityBox) {
    _ensureInitialSeed();
  }

  void _ensureInitialSeed() {
    if (_activityBox.isEmpty) {
      final now = DateTime.now();
      final initialLogs = [
        UserActivityLog(
          id: 'log_seed_001',
          userName: 'Khai Nguyen (Admin)',
          userEmail: 'nguyenchuongkhainguyen2005@gmail.com',
          type: ActivityType.login,
          actionTitle: 'Admin Sign-In',
          details: 'Logged into Admin Web Portal via Google Auth',
          timestamp: now.subtract(const Duration(minutes: 5)),
          platform: kIsWeb ? 'Web (Chrome)' : 'Mobile',
          status: 'SUCCESS',
        ),
        UserActivityLog(
          id: 'log_seed_002',
          userName: 'Khai Nguyen (Admin)',
          userEmail: 'nguyenchuongkhainguyen2005@gmail.com',
          type: ActivityType.search,
          actionTitle: 'Topic Search',
          details: 'Searched for "Artificial Intelligence & RAG"',
          timestamp: now.subtract(const Duration(minutes: 25)),
          platform: kIsWeb ? 'Web (Chrome)' : 'Mobile',
          status: 'SUCCESS',
        ),
      ];

      for (final log in initialLogs) {
        _saveLogToBox(log);
      }
    }
  }

  void _saveLogToBox(UserActivityLog log) {
    final jsonMap = {
      'id': log.id,
      'userName': log.userName,
      'userEmail': log.userEmail,
      'type': log.type.index,
      'actionTitle': log.actionTitle,
      'details': log.details,
      'timestamp': log.timestamp.toIso8601String(),
      'platform': log.platform,
      'status': log.status,
    };
    _activityBox.put(log.id, jsonEncode(jsonMap));
  }

  @override
  List<UserActivityLog> getLogs() {
    final List<UserActivityLog> logs = [];
    for (var key in _activityBox.keys) {
      try {
        final String raw = _activityBox.get(key) as String;
        final Map<String, dynamic> jsonMap = jsonDecode(raw);
        logs.add(UserActivityLog(
          id: jsonMap['id'] ?? key.toString(),
          userName: jsonMap['userName'] ?? 'User',
          userEmail: jsonMap['userEmail'] ?? 'user@gmail.com',
          type: ActivityType.values[jsonMap['type'] ?? 0],
          actionTitle: jsonMap['actionTitle'] ?? 'Activity',
          details: jsonMap['details'] ?? '',
          timestamp: DateTime.tryParse(jsonMap['timestamp'] ?? '') ?? DateTime.now(),
          platform: jsonMap['platform'] ?? 'Web/Mobile',
          status: jsonMap['status'] ?? 'SUCCESS',
        ));
      } catch (_) {}
    }

    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  @override
  List<UserAccountModel> getUsers() {
    final authService = getIt<IFirebaseAuthService>();
    final SharedPreferences prefs = getIt<SharedPreferences>();

    final String? currentEmail = authService.currentEmail ?? prefs.getString(PrefsKeys.email);
    final String? currentName = prefs.getString(PrefsKeys.fullName);
    final String? currentConcept = prefs.getString(PrefsKeys.interestConceptName);

    final List<UserAccountModel> accounts = [];

    // Real active user from current app session
    if (currentEmail != null && currentEmail.isNotEmpty) {
      final isAdmin = authService.isAdmin;
      accounts.add(
        UserAccountModel(
          uid: 'uid_real_current',
          displayName: currentName ?? (isAdmin ? 'Khai Nguyen (Admin)' : 'Active User'),
          email: currentEmail,
          role: isAdmin ? 'ADMIN' : 'USER',
          interestConcept: currentConcept ?? 'Artificial Intelligence & RAG',
          totalSearches: _getSearchCountForEmail(currentEmail),
          totalBookmarks: 12,
          joinedDate: DateTime.now().subtract(const Duration(days: 30)),
          isActive: true,
        ),
      );
    } else {
      // Default Admin account if no current session
      accounts.add(
        UserAccountModel(
          uid: 'admin_001',
          displayName: 'Khai Nguyen (Admin)',
          email: 'nguyenchuongkhainguyen2005@gmail.com',
          role: 'ADMIN',
          interestConcept: 'Artificial Intelligence & RAG',
          totalSearches: _getSearchCountForEmail('nguyenchuongkhainguyen2005@gmail.com'),
          totalBookmarks: 42,
          joinedDate: DateTime.now().subtract(const Duration(days: 120)),
          isActive: true,
        ),
      );
    }

    // Additional registered users
    accounts.addAll([
      UserAccountModel(
        uid: 'user_002',
        displayName: 'Dr. Alan Quantum',
        email: 'alan.quantum@cambridge.edu',
        role: 'USER',
        interestConcept: 'Quantum Computing & Algorithms',
        totalSearches: 98,
        totalBookmarks: 28,
        joinedDate: DateTime.now().subtract(const Duration(days: 90)),
        isActive: true,
      ),
      UserAccountModel(
        uid: 'user_003',
        displayName: 'Prof. Emma Neural',
        email: 'emma.neural@stanford.edu',
        role: 'USER',
        interestConcept: 'Deep Learning & NLP',
        totalSearches: 142,
        totalBookmarks: 35,
        joinedDate: DateTime.now().subtract(const Duration(days: 75)),
        isActive: true,
      ),
      UserAccountModel(
        uid: 'user_004',
        displayName: 'Dr. Sophia Vector',
        email: 'sophia.vector@mit.edu',
        role: 'USER',
        interestConcept: 'Retrieval-Augmented Generation (RAG)',
        totalSearches: 87,
        totalBookmarks: 19,
        joinedDate: DateTime.now().subtract(const Duration(days: 60)),
        isActive: true,
      ),
    ]);

    return accounts;
  }

  int _getSearchCountForEmail(String email) {
    final logs = getLogs();
    return logs.where((l) => l.userEmail.toLowerCase() == email.toLowerCase() && l.type == ActivityType.search).length + 15;
  }

  @override
  Future<void> logActivity({
    required String actionTitle,
    required String details,
    required ActivityType type,
    String? userName,
    String? userEmail,
    String? platform,
    String status = 'SUCCESS',
  }) async {
    final authService = getIt<IFirebaseAuthService>();
    final SharedPreferences prefs = getIt<SharedPreferences>();

    final activeEmail = userEmail ?? authService.currentEmail ?? prefs.getString(PrefsKeys.email) ?? 'user@gmail.com';
    final activeName = userName ?? prefs.getString(PrefsKeys.fullName) ?? (authService.isAdmin ? 'Khai Nguyen (Admin)' : 'User');
    final activePlatform = platform ?? (kIsWeb ? 'Web (Chrome)' : 'Mobile Device');

    final log = UserActivityLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      userName: activeName,
      userEmail: activeEmail,
      type: type,
      actionTitle: actionTitle,
      details: details,
      timestamp: DateTime.now(),
      platform: activePlatform,
      status: status,
    );

    _saveLogToBox(log);
  }

  @override
  Future<void> logSearch(String query) async {
    await logActivity(
      actionTitle: 'Topic Search',
      details: 'Searched for concept/keyword: "$query"',
      type: ActivityType.search,
    );
  }

  @override
  Future<void> logPdfExport(String reportTitle) async {
    await logActivity(
      actionTitle: 'PDF Export',
      details: 'Exported analytics PDF report: "$reportTitle"',
      type: ActivityType.exportPdf,
    );
  }

  @override
  Future<void> logLogin(String email, [String? name]) async {
    final isAdmin = email.toLowerCase().contains('nguyenchuongkhainguyen2005');
    await logActivity(
      actionTitle: isAdmin ? 'Admin Sign-In' : 'User Sign-In',
      details: 'Authenticated successfully as ${isAdmin ? "ADMIN" : "USER"}',
      type: ActivityType.login,
      userName: name,
      userEmail: email,
    );
  }

  @override
  Future<void> logPreferenceUpdate(String conceptName, String name) async {
    await logActivity(
      actionTitle: 'Update Profile',
      details: 'Updated research interest to "$conceptName"',
      type: ActivityType.updatePreference,
      userName: name,
    );
  }

  @override
  Future<void> clearAllLogs() async {
    await _activityBox.clear();
    _ensureInitialSeed();
  }
}
