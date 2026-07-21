import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

// ─── User Model (Admin View) ─────────────────────────────────────────────────

class AdminUserModel {
  final String uid;
  final String fullName;
  final String email;
  final String photoUrl;
  final String role;
  final bool isBlocked;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final int viewCount;
  final int pdfExportCount;

  const AdminUserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.photoUrl,
    required this.role,
    required this.isBlocked,
    this.createdAt,
    this.lastActiveAt,
    this.viewCount = 0,
    this.pdfExportCount = 0,
  });

  bool get isAdmin => role == 'admin';

  factory AdminUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminUserModel(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? 'Ẩn danh',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      isBlocked: data['isBlocked'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
      viewCount: data['viewCount'] as int? ?? 0,
      pdfExportCount: data['pdfExportCount'] as int? ?? 0,
    );
  }
}

// ─── Analytics Summary Model ──────────────────────────────────────────────────

class AppAnalyticsSummary {
  final int totalUsers;
  final int activeUsersThisWeek;
  final int totalPdfExports;
  final int totalViews;
  final List<Map<String, dynamic>> topPublications;
  final DateTime? lastUpdated;

  const AppAnalyticsSummary({
    this.totalUsers = 0,
    this.activeUsersThisWeek = 0,
    this.totalPdfExports = 0,
    this.totalViews = 0,
    this.topPublications = const [],
    this.lastUpdated,
  });

  factory AppAnalyticsSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppAnalyticsSummary(
      totalUsers: data['totalUsers'] as int? ?? 0,
      activeUsersThisWeek: data['activeUsersThisWeek'] as int? ?? 0,
      totalPdfExports: data['totalPdfExports'] as int? ?? 0,
      totalViews: data['totalViews'] as int? ?? 0,
      topPublications:
          (data['topPublications'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
              [],
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
}

// ─── Service Interface ────────────────────────────────────────────────────────

abstract class IFirebaseUserService {
  Future<bool> isAdmin(String uid);
  Stream<List<AdminUserModel>> watchAllUsers();
  Future<void> blockUser(String uid);
  Future<void> unblockUser(String uid);
  Future<void> setUserRole(String uid, String role);
  Future<AppAnalyticsSummary> getAnalyticsSummary();
  Future<int> getTotalUserCount();
}

// ─── Service Implementation ───────────────────────────────────────────────────

@LazySingleton(as: IFirebaseUserService)
class FirebaseUserService implements IFirebaseUserService {
  final FirebaseFirestore _firestore;

  FirebaseUserService() : _firestore = FirebaseFirestore.instance;

  @override
  Future<bool> isAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] == 'admin';
    } catch (e) {
      debugPrint('[FirebaseUserService] isAdmin error: $e');
      return false;
    }
  }

  @override
  Stream<List<AdminUserModel>> watchAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(AdminUserModel.fromFirestore).toList());
  }

  @override
  Future<void> blockUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isBlocked': true,
      'blockedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[FirebaseUserService] User $uid blocked.');
  }

  @override
  Future<void> unblockUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isBlocked': false,
      'blockedAt': FieldValue.delete(),
    });
    debugPrint('[FirebaseUserService] User $uid unblocked.');
  }

  @override
  Future<void> setUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
    debugPrint('[FirebaseUserService] User $uid role set to $role.');
  }

  @override
  Future<AppAnalyticsSummary> getAnalyticsSummary() async {
    try {
      final doc =
          await _firestore.collection('app_analytics').doc('summary').get();
      if (doc.exists) {
        return AppAnalyticsSummary.fromFirestore(doc);
      }
      // Fallback: compute from users collection
      final count = await getTotalUserCount();
      return AppAnalyticsSummary(totalUsers: count);
    } catch (e) {
      debugPrint('[FirebaseUserService] getAnalyticsSummary error: $e');
      return const AppAnalyticsSummary();
    }
  }

  @override
  Future<int> getTotalUserCount() async {
    try {
      final snapshot = await _firestore.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[FirebaseUserService] getTotalUserCount error: $e');
      return 0;
    }
  }
}
