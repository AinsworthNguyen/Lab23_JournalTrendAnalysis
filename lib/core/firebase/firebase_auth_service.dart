import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../injection_container.dart';

abstract class IFirebaseAuthService {
  Stream<User?> get authStateChanges;
  Future<UserCredential> signInWithGoogle();
  Future<void> signInBypass();
  Future<void> signInWithEmailDirect(String email);
  Future<void> signOut();
  User? get currentUser;
  String? get currentEmail;
  bool get isBypassed;
  bool get isAdmin;
}

@LazySingleton(as: IFirebaseAuthService)
class FirebaseAuthService implements IFirebaseAuthService {
  FirebaseAuthService()
    : _firebaseAuth = FirebaseAuth.instance,
      _googleSignIn = GoogleSignIn() {
    try {
      final SharedPreferences prefs = getIt<SharedPreferences>();
      _customEmail = prefs.getString('KEY_CUSTOM_EMAIL');
      if (_customEmail != null && _customEmail!.isNotEmpty) {
        _isBypassed = true;
      }
    } on Exception catch (_) {}
  }

  static const List<String> adminEmails = [
    'nguyenchuongkhainguyen2005@gmail.com',
  ];

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _isBypassed = false;
  String? _customEmail;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  String? get currentEmail => _firebaseAuth.currentUser?.email ?? _customEmail;

  @override
  bool get isBypassed => _isBypassed;

  @override
  bool get isAdmin {
    final String? email = currentEmail?.toLowerCase().trim();
    if (email == null) return false;
    return adminEmails.contains(email);
  }

  @override
  Future<void> signInBypass() async {
    _isBypassed = true;
    _customEmail = null;
    try {
      final SharedPreferences prefs = getIt<SharedPreferences>();
      await prefs.remove('KEY_CUSTOM_EMAIL');
    } on Exception catch (_) {}
  }

  @override
  Future<void> signInWithEmailDirect(String email) async {
    _isBypassed = true;
    _customEmail = email.trim();
    try {
      final SharedPreferences prefs = getIt<SharedPreferences>();
      await prefs.setString('KEY_CUSTOM_EMAIL', email.trim());
    } on Exception catch (_) {}
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final credential = await _firebaseAuth.signInWithPopup(googleProvider);
        _isBypassed = false;
        _customEmail = null;
        try {
          final SharedPreferences prefs = getIt<SharedPreferences>();
          await prefs.remove('KEY_CUSTOM_EMAIL');
        } on Exception catch (_) {}
        return credential;
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      _isBypassed = false;
      _customEmail = null;
      try {
        final SharedPreferences prefs = getIt<SharedPreferences>();
        await prefs.remove('KEY_CUSTOM_EMAIL');
      } on Exception catch (_) {}
      return await _firebaseAuth.signInWithCredential(credential);
    } on MissingPluginException {
      throw FirebaseAuthException(
        code: 'UNSUPPORTED_PLATFORM',
        message:
            'Google Sign-In is not supported on Windows. Please use "Continue as Guest" instead.',
      );
    } on PlatformException catch (e) {
      if (e.code == 'channel-error' ||
          e.message?.contains('implementation found') == true) {
        throw FirebaseAuthException(
          code: 'UNSUPPORTED_PLATFORM',
          message:
              'Google Sign-In is not supported on Windows. Please use "Continue as Guest" instead.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    _isBypassed = false;
    _customEmail = null;
    try {
      final SharedPreferences prefs = getIt<SharedPreferences>();
      await prefs.remove('KEY_CUSTOM_EMAIL');
    } on Exception catch (_) {}
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } on Exception catch (_) {}
    await _firebaseAuth.signOut();
  }
}
