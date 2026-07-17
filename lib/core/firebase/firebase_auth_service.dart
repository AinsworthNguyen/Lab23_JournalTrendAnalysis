import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

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
  final GoogleSignIn _googleSignIn;
  bool _isBypassed = false;

  FirebaseAuthService()
      : _firebaseAuth = FirebaseAuth.instance,
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
      return await _firebaseAuth.signInWithCredential(credential);
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

  @override
  Future<void> signOut() async {
    _isBypassed = false;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }
}
