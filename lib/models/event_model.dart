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

  final int capacity;        // cupo_maximo
  final bool isActive;       // estado_evento

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
    required this.organizerId,
    required this.organizerName,
    this.createdAt,
    this.updatedAt,
  });

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
        'organizerId': organizerId,
        'organizerName': organizerName,
        'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static EventModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    DateTime _ts(dynamic x) {
      if (x is Timestamp) return x.toDate();
      if (x is DateTime) return x;
      return DateTime.fromMillisecondsSinceEpoch(0); // ✅ “muy viejo” en vez de now()
    }

    return EventModel(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      category: (d['category'] ?? '').toString(),
      subcategory: (d['subcategory'] ?? '').toString(),
      location: (d['location'] ?? '').toString(),
      startAt: _ts(d['startAt']),
      endAt: _ts(d['endAt']),
      capacity: (d['capacity'] ?? 0) is int ? d['capacity'] : int.tryParse('${d['capacity']}') ?? 0,
      isActive: (d['isActive'] ?? true) == true,
      organizerId: (d['organizerId'] ?? '').toString(),
      organizerName: (d['organizerName'] ?? '').toString(),
      createdAt: d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : null,
      updatedAt: d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}
