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
  /// Đăng ký: email + username + password
  Future<void> signUpWithEmail({
    required String email,
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final trimmedEmail = email.trim();
    final usernameRef = _firestore.collection('usernames').doc(normalizedUsername);

    // Bước 1: "giữ chỗ" username bằng transaction — đảm bảo không 2 người
    // cùng đăng ký trùng username dù bấm gần như đồng thời (khắc phục race condition).
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(usernameRef);
      if (snapshot.exists) {
        throw Exception('username-already-taken');
      }
      tx.set(usernameRef, {
        'uid': '', // cập nhật uid thật ngay sau khi tạo tài khoản Auth thành công
        'email': trimmedEmail,
        'reservedAt': Timestamp.now(),
      });
    });

    String? createdUid;
    try {
      // Bước 2: tạo tài khoản Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      createdUid = credential.user!.uid;

      // Bước 3: hoàn tất mapping username -> uid thật + tạo profile
      await usernameRef.set({'uid': createdUid, 'email': trimmedEmail});
      await _firestore.collection('users').doc(createdUid).set({
        'email': trimmedEmail,
        'username': normalizedUsername,
        'displayName': normalizedUsername,
        'createdAt': Timestamp.now(),
      });

      await _auth.signOut();
    } catch (e) {
      // Rollback: có lỗi ở bất kỳ bước nào sau khi đã giữ chỗ username →
      // giải phóng username, và nếu tài khoản Auth đã lỡ tạo thì xoá luôn,
      // tránh để lại tài khoản "mồ côi" không đăng nhập được.
      await usernameRef.delete().catchError((_) => usernameRef);
      if (createdUid != null) {
        try {
          await _auth.currentUser?.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
    // Kiểm tra username đã tồn tại chưa
 

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
 Future<void> sendPasswordResetByUsername(String username) async {
    final normalizedUsername = username.trim().toLowerCase();

    final doc = await _firestore.collection('usernames').doc(normalizedUsername).get();
    if (!doc.exists) {
      throw Exception('username-not-found');
    }

    final email = doc.data()!['email'] as String;
    await _auth.sendPasswordResetEmail(email: email);
  }
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}