import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final String location;

  final DateTime startAt;
  final DateTime endAt;

  final int capacity; // cupo_maximo
  final bool isActive; // estado_evento

  final int registrationsCount; // ✅ conteo de registros (para cupo)

  final String organizerId;
  final String organizerName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.location,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.isActive,
    required this.registrationsCount,
    required this.organizerId,
    required this.organizerName,
    this.createdAt,
    this.updatedAt,
  });

  // ✅ Helpers
  int get remaining => (capacity - registrationsCount).clamp(0, capacity);
  bool get isFull => remaining <= 0;

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'subcategory': subcategory,
        'location': location,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'capacity': capacity,
        'isActive': isActive,
        'registrationsCount': registrationsCount,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static EventModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    DateTime parseTimestamp(dynamic x) {
      if (x is Timestamp) return x.toDate();
      if (x is DateTime) return x;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    int parseInt(dynamic x) {
      if (x is int) return x;
      return int.tryParse('$x') ?? 0;
    }

    return EventModel(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      category: (d['category'] ?? '').toString(),
      subcategory: (d['subcategory'] ?? '').toString(),
      location: (d['location'] ?? '').toString(),
      startAt: parseTimestamp(d['startAt']),
      endAt: parseTimestamp(d['endAt']),
      capacity: parseInt(d['capacity']),
      isActive: (d['isActive'] ?? true) == true,
      registrationsCount: parseInt(d['registrationsCount']),
      organizerId: (d['organizerId'] ?? '').toString(),
      organizerName: (d['organizerName'] ?? '').toString(),
      createdAt:
          d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : null,
      updatedAt:
          d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}

