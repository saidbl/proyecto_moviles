import 'package:flutter/material.dart';
import '../../models/my_registration_model.dart';

class CertificateScreen extends StatelessWidget {
  final MyRegistration reg;
  final String studentName;
  final String studentEmail;

  const CertificateScreen({
    super.key,
    required this.reg,
    required this.studentName,
    required this.studentEmail,
  });

  @override
  Widget build(BuildContext context) {
    final title = reg.eventTitle ?? 'Evento';
    final endAt = reg.eventEndAt;

    return Scaffold(
      appBar: AppBar(title: const Text('Constancia')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.verified, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'CONSTANCIA DE PARTICIPACIÓN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Se hace constar que:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              studentName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              studentEmail,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Participó en el evento:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha de término: ${_fmt(endAt)}',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            const Text(
              'Esta constancia es válida para fines académicos.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime? d) => d == null ? 'No disponible' : '${d.day}/${d.month}/${d.year}';
}
