import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyAttendanceQrScreen extends StatelessWidget {
  final String eventId;

  const MyAttendanceQrScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final qrData = jsonEncode({
      'eventId': eventId,
      'userId': uid,
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Mi QR de asistencia')),
      body: Center(
        child: QrImageView(
          data: qrData,
          size: 260,
        ),
      ),
    );
  }
}
