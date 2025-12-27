import 'package:cloud_firestore/cloud_firestore.dart';

class MyRegistration {
  final String eventId;
  final String? eventTitle;
  final String? eventLocation;
  final DateTime? eventStartAt;
  final DateTime? eventEndAt;

  MyRegistration({
    required this.eventId,
    this.eventTitle,
    this.eventLocation,
    this.eventStartAt,
    this.eventEndAt,
  });

  static MyRegistration fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();

    DateTime? ts(dynamic x) {
      if (x is Timestamp) return x.toDate();
      if (x is DateTime) return x;
      return null;
    }

    final inferredEventId = _inferEventIdFromPath(doc.reference.path);

    return MyRegistration(
      eventId: (d['eventId']?.toString().isNotEmpty == true) ? d['eventId'].toString() : inferredEventId,
      eventTitle: d['eventTitle']?.toString(),
      eventLocation: d['eventLocation']?.toString(),
      eventStartAt: ts(d['eventStartAt']),
      eventEndAt: ts(d['eventEndAt']),
    );
  }

  // fallback: .../events/{eventId}/registrations/{uid}
  static String _inferEventIdFromPath(String path) {
    final parts = path.split('/');
    final idx = parts.indexOf('events');
    if (idx != -1 && idx + 1 < parts.length) return parts[idx + 1];
    return '';
  }
}
