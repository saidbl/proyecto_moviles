import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  String get _uid {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw Exception('No hay sesión activa');
    return u.uid;
  }

  Stream<AppUser> streamMe() {
    return _db.collection('users').doc(_uid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return AppUser.fromMap(data);
    });
  }

  Future<void> updateMe({
    String? name,
    String? photoUrl,
    List<String>? interests,
    Map<String, dynamic>? notificationPrefs,
  }) async {
    final update = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) update['name'] = name.trim();
    if (photoUrl != null) update['photoUrl'] = photoUrl.trim().isEmpty ? null : photoUrl.trim();
    if (interests != null) update['interests'] = interests;
    if (notificationPrefs != null) update['notificationPrefs'] = notificationPrefs;

    await _db.collection('users').doc(_uid).update(update);
  }
}
