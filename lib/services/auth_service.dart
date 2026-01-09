import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //  Admin único
  static const String adminEmail = 'admin@ipn.mx';

  // Dominios
  static const String domainStudent = '@alumno.ipn.mx';
  static const String domainOrganizer = '@organizadores.ipn.mx';

  String normalizeEmail(String email) => email.trim().toLowerCase();

  /// Para login/reset: correos permitidos (alumno, organizador, admin)
  bool isAllowedEmail(String email) {
    final e = normalizeEmail(email);
    return e == adminEmail ||
        e.endsWith(domainOrganizer) ||
        e.endsWith(domainStudent);
  }

  // =====================================================
  // LOGIN
  // =====================================================
  Future<User?> signIn(String email, String password) async {
    final cleanEmail = normalizeEmail(email);

    final result = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password.trim(),
    );

    return result.user;
  }

  // =====================================================
  // REGISTRO (SOLO ALUMNOS)
  // =====================================================
  Future<User?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final cleanEmail = normalizeEmail(email);
    final cleanName = name.trim();
    final cleanPassword = password.trim();

    //  Bloquear admin
    if (cleanEmail == adminEmail) {
      throw Exception('La cuenta de administrador no se registra desde la app.');
    }

    //  Bloquear organizadores
    if (cleanEmail.endsWith(domainOrganizer)) {
      throw Exception('Las cuentas de organizador las crea el administrador.');
    }

    //  Permitir SOLO alumnos
    if (!cleanEmail.endsWith(domainStudent)) {
      throw Exception('Solo se permite registro con correo $domainStudent');
    }

    final result = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    final user = result.user;

    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': cleanName,
        'email': cleanEmail,
        'role': 'estudiante', //  fijo: solo alumnos se registran
        'photoUrl': null,
        'interests': [],
        'notificationPrefs': {
          'reminders': true,
          'organizerAlerts': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // =====================================================
  // RECUPERAR CONTRASEÑA (alumnos + organizadores + admin)
  // =====================================================
  Future<void> resetPassword(String email) async {
    final cleanEmail = normalizeEmail(email);

    if (!isAllowedEmail(cleanEmail)) {
      throw Exception(
        'Correo no permitido. Usa $domainStudent o $domainOrganizer.',
      );
    }

    await _auth.sendPasswordResetEmail(email: cleanEmail);
  }

  User? currentUser() => _auth.currentUser;
}
