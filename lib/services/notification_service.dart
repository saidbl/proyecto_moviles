import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obtener notificaciones del usuario
  Stream<List<AppNotification>> getMyNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppNotification.fromFirestore(d)).toList());
  }

  /// Crear notificación
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marcar como leída
  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  // eliminarla
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error eliminando notificación: $e');
      rethrow;
    }
  }
}
