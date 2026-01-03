import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../models/my_registration_model.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class EventService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();
  final _notificationService = NotificationService();

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
    File? imageFile,
  }) async {
    final me = await _userService.streamMe().first;

    final doc =await _db.collection('events').add({
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
      'organizerNotificationPrefs': me.notificationPrefs,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (imageFile != null) {
    final url = await _uploadEventImage(
      file: imageFile,
      eventId: doc.id,
    );

    await doc.update({'imageUrl': url});
  }
    await _notificationService.createNotification(
      userId: _uid,
      title: 'Evento creado',
      message: 'Tu evento "$title" fue publicado correctamente.',
    );

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
    File? imageFile,
  }) async {
    final data = {
    'title': title.trim(),
    'description': description.trim(),
    'category': category.trim(),
    'subcategory': subcategory.trim(),
    'location': location.trim(),
    'startAt': Timestamp.fromDate(startAt),
    'endAt': Timestamp.fromDate(endAt),
    'capacity': capacity,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  if (imageFile != null) {
    final url = await _uploadEventImage(
      file: imageFile,
      eventId: eventId,
    );
    data['imageUrl'] = url;
  }

  await _db.collection('events').doc(eventId).update(data);
  }

  Future<void> cancelEvent(String eventId) async {
    await _db.collection('events').doc(eventId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notificationService.createNotification(
      userId: _uid,
      title: 'Evento cancelado',
      message: 'El evento fue marcado como cancelado.',
    );

  }

  // =========================
  // REGISTROS (SPRINT 3)
  // =========================

  /// ✅ Registrar alumno al evento (transaction)
  Future<void> registerToEvent(String eventId) async {
    final me = await _userService.streamMe().first;

    final eventRef = _db.collection('events').doc(eventId);
    final regRef = eventRef.collection('registrations').doc(_uid);
    final eventSnap = await _db.collection('events').doc(eventId).get();
    final eventTitle = (eventSnap.data()?['title'] ?? 'Evento').toString();


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
        'attended': false, 
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
    await _notificationService.createNotification(
      userId: _uid,
      title: 'Inscripción exitosa',
      message: 'Te inscribiste al evento "$eventTitle".',
    );
    final data = eventSnap.data()!;
    final organizerId = data['organizerId'];

    final organizerPrefs =
    data['organizerNotificationPrefs'] ?? {};

    final wantsAlerts = organizerPrefs['organizerAlerts'] ?? true;


    if (wantsAlerts) {
      await _notificationService.createNotification(
        userId: organizerId,
        title: 'Nuevo registro',
        message: '${me.name} se registró en tu evento "$eventTitle".',
      );
    }


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
    final eventSnap = await _db.collection('events').doc(eventId).get();
    final eventTitle = (eventSnap.data()?['title'] ?? 'Evento').toString();

    await _notificationService.createNotification(
      userId: _uid,
      title: 'Registro cancelado',
      message: 'Cancelaste tu registro al evento "$eventTitle".',
    );

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

  Future<void> sendUpcomingEventReminders() async {
      final now = DateTime.now();
      final soon = now.add(const Duration(hours: 24));

      final events = await _db
          .collection('events')
          .where('isActive', isEqualTo: true)
          .where('startAt', isGreaterThan: Timestamp.fromDate(now))
          .where('startAt', isLessThan: Timestamp.fromDate(soon))
          .get();

      for (final e in events.docs) {
        final eventId = e.id;
        final title = e['title'];

        final regs = await _db
            .collection('events')
            .doc(eventId)
            .collection('registrations')
            .get();

        for (final r in regs.docs) {
          final userId = r['userId'];

          final userSnap = await _db.collection('users').doc(userId).get();
          final prefs = userSnap.data()?['notificationPrefs'] ?? {};
          final wantsReminders = prefs['reminders'] ?? true;

          if (wantsReminders) {
            await _notificationService.createNotification(
              userId: userId,
              title: 'Evento próximo',
              message: 'Recuerda que el evento "$title" es pronto.',
            );
          }
        }
      }
    }

    Future<void> markAttendanceByOrganizer({
  required String eventId,
  required String userId,
}) async {
  final regRef = _db
      .collection('events')
      .doc(eventId)
      .collection('registrations')
      .doc(userId);

  final snap = await regRef.get();

  if (!snap.exists) {
    throw Exception('El alumno no está registrado');
  }

  if (snap.data()?['attended'] == true) {
    throw Exception('Asistencia ya registrada');
  }

  await regRef.update({
    'attended': true,
    'attendedAt': FieldValue.serverTimestamp(),
  });
}

Future<String> _uploadEventImage({
  required File file,
  required String eventId,
}) async {
  final ref = FirebaseStorage.instance
      .ref()
      .child('events')
      .child(eventId)
      .child('cover.jpg');

  await ref.putFile(file);
  return await ref.getDownloadURL();
}


}
