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
  Future<void> seedSampleData();
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

  @override
  Future<void> seedSampleData() async {
    final batch = _firestore.batch();

    final users = [
      {
        'id': 'sample_admin_1',
        'fullName': 'System Admin (You)',
        'email': 'admin@journaltrend.com',
        'photoUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        'role': 'admin',
        'isBlocked': false,
        'viewCount': 145,
        'pdfExportCount': 12,
      },
      {
        'id': 'sample_user_1',
        'fullName': 'Dr. Alan Turing',
        'email': 'alan.turing@cambridge.edu',
        'photoUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'role': 'user',
        'isBlocked': false,
        'viewCount': 89,
        'pdfExportCount': 7,
      },
      {
        'id': 'sample_user_2',
        'fullName': 'Prof. Geoffrey Hinton',
        'email': 'hinton@toronto.edu',
        'photoUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        'role': 'user',
        'isBlocked': false,
        'viewCount': 210,
        'pdfExportCount': 25,
      },
      {
        'id': 'sample_user_3',
        'fullName': 'Dr. Fei-Fei Li',
        'email': 'feifeili@stanford.edu',
        'photoUrl': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
        'role': 'user',
        'isBlocked': false,
        'viewCount': 312,
        'pdfExportCount': 40,
      },
      {
        'id': 'sample_user_4',
        'fullName': 'Spam Bot 9000',
        'email': 'spambot@malicious.com',
        'photoUrl': '',
        'role': 'user',
        'isBlocked': true,
        'viewCount': 2,
        'pdfExportCount': 0,
      },
      {
        'id': 'sample_user_5',
        'fullName': 'Abusive Account',
        'email': 'badactor@tempmail.com',
        'photoUrl': '',
        'role': 'user',
        'isBlocked': true,
        'viewCount': 5,
        'pdfExportCount': 0,
      },
    ];

    for (final u in users) {
      final ref = _firestore.collection('users').doc(u['id'] as String);
      batch.set(ref, {
        'fullName': u['fullName'],
        'email': u['email'],
        'photoUrl': u['photoUrl'],
        'role': u['role'],
        'isBlocked': u['isBlocked'],
        'viewCount': u['viewCount'],
        'pdfExportCount': u['pdfExportCount'],
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    }

    final analyticsRef = _firestore.collection('app_analytics').doc('summary');
    batch.set(analyticsRef, {
      'totalUsers': 6,
      'activeUsersThisWeek': 4,
      'totalPdfExports': 84,
      'totalViews': 763,
      'lastUpdated': FieldValue.serverTimestamp(),
      'topPublications': [
        {'title': 'Attention Is All You Need', 'viewCount': 352},
        {'title': 'Deep Residual Learning for Image Recognition', 'viewCount': 284},
        {'title': 'Generative Adversarial Nets', 'viewCount': 198},
        {'title': 'Mastering the Game of Go with Deep Neural Networks', 'viewCount': 145},
        {'title': 'BERT: Pre-training of Deep Bidirectional Transformers', 'viewCount': 120},
      ],
    });

    await batch.commit();
    debugPrint('[FirebaseUserService] Seeded sample data successfully.');
  }
}
