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

  final int capacity; 
  final bool isActive; 

  final int registrationsCount; 

  final String organizerId;
  final String organizerName;

  final List<String> allowedUserIds; 
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? imageUrl;

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
    required this.allowedUserIds, 
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  int get remaining => (capacity - registrationsCount).clamp(0, capacity);
  bool get isFull => remaining <= 0;

  bool get hasStarted => DateTime.now().isAfter(startAt);
  bool get hasEnded => DateTime.now().isAfter(endAt);

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
        'allowedUserIds': allowedUserIds, 
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
        if (imageUrl != null) 'imageUrl': imageUrl,
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

    // Lógica segura para allowedUserIds
    // Si el evento es viejo y no tiene el campo, asumimos que solo el organizador está permitido.
    List<String> parseAllowed(dynamic x) {
      if (x is List) return List<String>.from(x);
      // Fallback para eventos antiguos:
      final orgId = (d['organizerId'] ?? '').toString();
      return orgId.isNotEmpty ? [orgId] : [];
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
      // Parseamos la lista
      allowedUserIds: parseAllowed(d['allowedUserIds']), 
      imageUrl: d['imageUrl'],
      createdAt:
          d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : null,
      updatedAt:
          d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}