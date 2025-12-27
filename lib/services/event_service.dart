import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../models/my_registration_model.dart';
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

  // =========================
  // HELPERS
  // =========================
  int _readInt(Map<String, dynamic> data, String key, {int def = 0}) {
    final v = data[key];
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? def;
  }

  DateTime? _readDate(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  // =========================
  // STREAMS
  // =========================
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

  Stream<EventModel> streamEventById(String eventId) {
    return _db.collection('events').doc(eventId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Evento no encontrado');
      return EventModel.fromDoc(doc);
    });
  }

  Stream<bool> streamAmIRegistered(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(_uid)
        .snapshots()
        .map((d) => d.exists);
  }

  /// ✅ Mis registros (ALUMNO)
  /// IMPORTANTE: NO usamos orderBy(createdAt) para evitar índices/errores.
  /// - Solo trae docs NUEVOS (los que tengan userId).
  /// - Los viejos se arreglan con ensureRegistrationProjectionIfNeeded().
  Stream<List<MyRegistration>> streamMyRegistrations() {
  return _db
      .collectionGroup('registrations')
      .where('userId', isEqualTo: _uid)
      .snapshots()
      .map((q) {
        final list = q.docs.map(MyRegistration.fromDoc).toList();

        // Orden local (no requiere índice)
        list.sort((a, b) {
          final ad = a.eventStartAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.eventStartAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

        return list;
      });
}

  // =========================
  // CREATE / UPDATE / CANCEL
  // =========================
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
      'registrationsCount': 0,
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

  // =========================
  // REGISTROS (SPRINT 3)
  // =========================

  /// ✅ Registrar alumno al evento (transaction)
  Future<void> registerToEvent(String eventId) async {
    final me = await _userService.streamMe().first;

    final eventRef = _db.collection('events').doc(eventId);
    final regRef = eventRef.collection('registrations').doc(_uid);

    await _db.runTransaction((tx) async {
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) throw Exception('Evento no existe');

      final data = (eventSnap.data() ?? <String, dynamic>{}) as Map<String, dynamic>;

      final isActive = (data['isActive'] ?? true) == true;
      if (!isActive) throw Exception('Este evento fue cancelado');

      final capacity = _readInt(data, 'capacity', def: 0);
      final count = _readInt(data, 'registrationsCount', def: 0);

      if (capacity <= 0) {
        throw Exception('El evento no tiene cupo configurado (capacity=0).');
      }

      // Ya registrado?
      final regSnap = await tx.get(regRef);
      if (regSnap.exists) throw Exception('Ya estás registrado en este evento');

      // Cupo
      if (count >= capacity) throw Exception('Evento lleno');

      // Datos del evento para "Mis registros"
      final eventTitle = (data['title'] ?? '').toString();
      final eventLocation = (data['location'] ?? '').toString();
      final eventStartAt = _readDate(data, 'startAt');
      final eventEndAt = _readDate(data, 'endAt');

      tx.set(regRef, {
        'userId': _uid, // ✅ clave para streamMyRegistrations()
        'userName': me.name,
        'userEmail': me.email,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'registered',

        'eventId': eventId,
        'eventTitle': eventTitle.isEmpty ? '(Sin título)' : eventTitle,
        'eventLocation': eventLocation,
        if (eventStartAt != null) 'eventStartAt': Timestamp.fromDate(eventStartAt),
        if (eventEndAt != null) 'eventEndAt': Timestamp.fromDate(eventEndAt),
      });

      tx.update(eventRef, {
        'registrationsCount': count + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// ✅ Cancelar registro (transaction)
  Future<void> unregisterFromEvent(String eventId) async {
    final eventRef = _db.collection('events').doc(eventId);
    final regRef = eventRef.collection('registrations').doc(_uid);

    await _db.runTransaction((tx) async {
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) throw Exception('Evento no existe');

      final data = (eventSnap.data() ?? <String, dynamic>{}) as Map<String, dynamic>;
      final count = _readInt(data, 'registrationsCount', def: 0);

      final regSnap = await tx.get(regRef);
      if (!regSnap.exists) throw Exception('No estabas registrado en este evento');

      tx.delete(regRef);

      final next = count - 1;
      tx.update(eventRef, {
        'registrationsCount': next < 0 ? 0 : next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// ✅ “Backfill” para registros viejos:
  /// Si el alumno YA está registrado (doc existe) pero NO tiene userId/eventTitle, etc.,
  /// los agregamos con merge (sin borrar nada).
  ///
  /// LLÁMALO cuando abras el detalle del evento y detectes que amIRegistered == true.
  Future<void> ensureRegistrationProjectionIfNeeded(EventModel event) async {
    final regRef = _db.collection('events').doc(event.id).collection('registrations').doc(_uid);

    final snap = await regRef.get();
    if (!snap.exists) return;

    final data = (snap.data() ?? <String, dynamic>{}) as Map<String, dynamic>;

    final needsUserId = (data['userId'] ?? '').toString().isEmpty;
    final needsEventId = (data['eventId'] ?? '').toString().isEmpty;
    final needsTitle = data['eventTitle'] == null;
    final needsLocation = data['eventLocation'] == null;
    final needsStart = data['eventStartAt'] == null;
    final needsEnd = data['eventEndAt'] == null;

    if (!(needsUserId || needsEventId || needsTitle || needsLocation || needsStart || needsEnd)) {
      return;
    }

    await regRef.set({
      'userId': _uid,
      'eventId': event.id,
      'eventTitle': event.title,
      'eventLocation': event.location,
      'eventStartAt': Timestamp.fromDate(event.startAt),
      'eventEndAt': Timestamp.fromDate(event.endAt),
      // NO tocamos createdAt ni status (se quedan como estén)
    }, SetOptions(merge: true));
  }
}
