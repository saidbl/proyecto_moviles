import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/event_service.dart';

class ScanAttendanceScreen extends StatelessWidget {
  final String eventId;

  const ScanAttendanceScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear asistencia')),
      body: MobileScanner(
        onDetect: (capture) async {
          final raw = capture.barcodes.first.rawValue;
          if (raw == null) return;

          try {
            final data = jsonDecode(raw);
            final qrEventId = data['eventId'];
            final userId = data['userId'];

            if (qrEventId != eventId) {
              throw Exception('QR no pertenece a este evento');
            }

            await eventService.markAttendanceByOrganizer(
              eventId: eventId,
              userId: userId,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Asistencia registrada')),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
      ),
    );
  }
}
