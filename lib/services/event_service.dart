import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../services/user_service.dart';

class EventService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('No hay sesión activa');
    return u.uid;
  }

  // Streams
  Stream<List<EventModel>> streamAllActiveEvents() {
    return _db
        .collection('events')
        .where('isActive', isEqualTo: true)
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((q) => q.docs.map(EventModel.fromDoc).toList());
  }

  Stream<List<EventModel>> streamAllEventsAdmin() {
    return _db
        .collection('events')
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((q) => q.docs.map(EventModel.fromDoc).toList());
  }

  Stream<List<EventModel>> streamMyEvents() {
    return _db
        .collection('events')
        .where('organizerId', isEqualTo: _uid)
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((q) => q.docs.map(EventModel.fromDoc).toList());
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required String category,
    required String subcategory,
    required String location,
    required DateTime startAt,
    required DateTime endAt,
    required int capacity,
  }) async {
    final me = await _userService.streamMe().first;

    await _db.collection('events').add({
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'subcategory': subcategory.trim(),
      'location': location.trim(),
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'capacity': capacity,
      'isActive': true,
      'organizerId': _uid,
      'organizerName': me.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required String category,
    required String subcategory,
    required String location,
    required DateTime startAt,
    required DateTime endAt,
    required int capacity,
  }) async {
    await _db.collection('events').doc(eventId).update({
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'subcategory': subcategory.trim(),
      'location': location.trim(),
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'capacity': capacity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelEvent(String eventId) async {
    await _db.collection('events').doc(eventId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
