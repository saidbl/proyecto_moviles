class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // estudiante | organizador | admin
  final String? photoUrl;
  final List<String> interests;
  final Map<String, dynamic> notificationPrefs;
  final String? fcmToken;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'estudiante',
    this.photoUrl,
    this.interests = const [],
    this.notificationPrefs = const {
      'reminders': true,
      'organizerAlerts': true,
    },
    this.fcmToken,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'photoUrl': photoUrl,
        'interests': interests,
        'notificationPrefs': notificationPrefs,
      };

  static AppUser fromMap(Map<String, dynamic> map) {
    // 1) Leer y normalizar
    String rawRole =
        (map['role'] ?? 'estudiante').toString().toLowerCase().trim();

    // 2) Corregir typos comunes (por ejemplo: "organizador" con d)
    if (rawRole == 'organizador') rawRole = 'organizador';

    // 3) Aceptar solo roles válidos
    const validRoles = {'admin', 'organizador', 'estudiante'};
    final role = validRoles.contains(rawRole) ? rawRole : 'estudiante';

    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: role,
      photoUrl: map['photoUrl'],
      interests: List<String>.from(map['interests'] ?? []),
      notificationPrefs: Map<String, dynamic>.from(
        map['notificationPrefs'] ??
            const {
              'reminders': true,
              'organizerAlerts': true,
            },
      ),
      fcmToken: map['fcmToken'],
    );
  }
}
