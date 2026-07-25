import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import '../constants/admin_accounts.dart';

abstract class IFirebaseAuthService {
  Stream<User?> get authStateChanges;
  Future<UserCredential> signInWithGoogle();
  Future<void> signInBypass();
  Future<void> signOut();
  User? get currentUser;
  bool get isBypassed;
}

@LazySingleton(as: IFirebaseAuthService)
class FirebaseAuthService implements IFirebaseAuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  bool _isBypassed = false;

  FirebaseAuthService()
      : _firebaseAuth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance,
        _googleSignIn = GoogleSignIn();

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  bool get isBypassed => _isBypassed;

  @override
  Future<void> signInBypass() async {
    _isBypassed = true;
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      _isBypassed = false;
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      await _syncUserProfile(userCredential.user);
      return userCredential;
    } on MissingPluginException {
      throw FirebaseAuthException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Google Sign-In is not supported on Windows. Please use "Continue as Guest" instead.',
      );
    } on PlatformException catch (e) {
      if (e.code == 'channel-error' || e.message?.contains('implementation found') == true) {
        throw FirebaseAuthException(
          code: 'UNSUPPORTED_PLATFORM',
          message: 'Google Sign-In is not supported on Windows. Please use "Continue as Guest" instead.',
        );
      }
      rethrow;
    }
  }

  Future<void> _syncUserProfile(User? user) async {
    if (user == null) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await userRef.get();
      final existingRole = snapshot.data()?['role'] as String?;
      final existingIsBlocked = snapshot.data()?['isBlocked'] as bool?;
      final role = AdminAccounts.isAdminEmail(user.email)
          ? 'admin'
          : existingRole ?? 'user';

      final data = <String, Object?>{
        'fullName': user.displayName ?? user.email ?? 'Google User',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'role': role,
        'isBlocked': existingIsBlocked ?? false,
        'lastActiveAt': FieldValue.serverTimestamp(),
      };
      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await userRef.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirebaseAuthService] Failed to sync user profile: $e');
    }
  }

  @override
  Future<void> signOut() async {
    _isBypassed = false;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }
}
