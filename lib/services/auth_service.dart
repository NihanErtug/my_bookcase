import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? get currentUserId => _firebaseAuth.currentUser?.uid;
  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  // kullanıcı çıkış yaptı mı? yoksa hala giriş yapmış şekilde içerde mi? takibi için.

  Future<void> createUser({
    required String email,
    required String password,
    required String username,
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);

    await userCredential.user?.updateDisplayName(username);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

final authProvider = Provider<Auth>((ref) => Auth());

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.authStateChanges;
});
