import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> createOrganizer({
    required String email,
    required String password,
    required String name,
  }) async {
    // Crear usuario en Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    // Crear documento en Firestore
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'role': 'organizador',
      'photoUrl': null,
      'interests': [],
      'notificationPrefs': {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
