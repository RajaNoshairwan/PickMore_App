import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/collections.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentAuthUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<AppUser?> fetchProfile(String uid) async {
    // Try customer first, then admin.
    final cDoc = await _db.collection(FireCollections.customers).doc(uid).get();
    if (cDoc.exists) return AppUser.fromMap(uid, cDoc.data()!);
    final aDoc = await _db.collection(FireCollections.admins).doc(uid).get();
    if (aDoc.exists) return AppUser.fromMap(uid, aDoc.data()!);
    return null;
  }

  Future<AppUser> signUpCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final user = AppUser(
      uid: uid,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      role: 'customer',
      createdAt: DateTime.now(),
    );
    await _db
        .collection(FireCollections.customers)
        .doc(uid)
        .set({...user.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    return user;
  }

  Future<AppUser> signInCustomer({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _db.collection(FireCollections.customers).doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('This account is not registered as a customer.');
    }
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<AppUser> signInAdmin({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _db.collection(FireCollections.admins).doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('This account is not an admin.');
    }
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final user = _auth.currentUser!;
    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }
}