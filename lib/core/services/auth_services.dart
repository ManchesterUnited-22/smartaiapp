// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng ký: email + username + password
  Future<void> signUpWithEmail({
    required String email,
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    // Kiểm tra username đã tồn tại chưa
    final existing = await _firestore.collection('usernames').doc(normalizedUsername).get();
    if (existing.exists) {
      throw Exception('username-already-taken');
    }

    // Tạo tài khoản Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    // Lưu mapping username -> email/uid (để login bằng username sau này)
    await _firestore.collection('usernames').doc(normalizedUsername).set({
      'uid': uid,
      'email': email.trim(),
    });

    // Lưu profile user
    await _firestore.collection('users').doc(uid).set({
      'email': email.trim(),
      'username': normalizedUsername,
      'displayName': normalizedUsername,
      'createdAt': Timestamp.now(),
    });

    await _auth.signOut();
  }

  /// Đăng nhập: chỉ cần username + password
  Future<UserCredential> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    final doc = await _firestore.collection('usernames').doc(normalizedUsername).get();
    if (!doc.exists) {
      throw Exception('username-not-found');
    }

    final email = doc.data()!['email'] as String;

    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);

    // Nếu là user Google lần đầu, tạo profile luôn
    final userDoc = _firestore.collection('users').doc(result.user!.uid);
    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      await userDoc.set({
        'email': result.user!.email,
        'displayName': result.user!.displayName ?? '',
        'avatarUrl': result.user!.photoURL ?? '',
        'createdAt': Timestamp.now(),
      });
    }

    return result;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}