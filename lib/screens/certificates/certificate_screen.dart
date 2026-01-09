import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Constancia',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _CertificateCard(
            theme: theme,
            studentName: studentName,
            studentEmail: studentEmail,
            title: title,
            endAt: endAt,
          ),
        ),
      ),
    );
  }
}

class _CertificateCard extends StatefulWidget {
  final ThemeData theme;
  final String studentName;
  final String studentEmail;
  final String title;
  final DateTime? endAt;

  const _CertificateCard({
    required this.theme,
    required this.studentName,
    required this.studentEmail,
    required this.title,
    required this.endAt,
  });

  @override
  State<_CertificateCard> createState() => _CertificateCardState();
}

class _CertificateCardState extends State<_CertificateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ============================
  /// 📄 GENERAR Y DESCARGAR PDF
  /// ============================
  Future<void> _downloadPdf() async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 2),
          ),
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              /// 🏛 ENCABEZADO
              pw.Text(
                'INSTITUTO POLITÉCNICO NACIONAL',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Text(
                'Unidad Académica',
                style: const pw.TextStyle(fontSize: 11),
              ),

              pw.SizedBox(height: 30),

              /// 🏷 TÍTULO PRINCIPAL
              pw.Text(
                'CONSTANCIA DE PARTICIPACIÓN',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              pw.SizedBox(height: 30),

              /// 📄 TEXTO FORMAL
              pw.Text(
                'Por medio de la presente se hace constar que:',
                style: const pw.TextStyle(fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 20),

              /// 👤 NOMBRE
              pw.Text(
                widget.studentName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 6),

              pw.Text(
                widget.studentEmail,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),

              pw.SizedBox(height: 30),

              pw.Text(
                'Participó activamente en el evento académico:',
                style: const pw.TextStyle(fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 12),

              /// 🎤 EVENTO
              pw.Text(
                widget.title,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'Celebrado y concluido el día ${_fmt(widget.endAt)}.',
                style: const pw.TextStyle(fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),

              pw.Spacer(),

              /// ✍ FIRMA
              pw.Divider(),

              pw.SizedBox(height: 12),

              pw.Text(
                'Para los fines académicos que convengan al interesado.',
                style: const pw.TextStyle(fontSize: 11),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 24),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('________________________'),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Organizador del evento',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('________________________'),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Sello institucional',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  /// 📥 DESCARGAR / COMPARTIR
  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}


  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 40,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 32,
        ),
        child: Column(
          children: [
            /// 🎓 ICONO
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 40,
                color: widget.theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 20),

            /// 🏷 TÍTULO
            const Text(
              'CONSTANCIA DE PARTICIPACIÓN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),

            const SizedBox(height: 28),

            Text('Se hace constar que:'),

            const SizedBox(height: 10),

            Text(
              widget.studentName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              widget.studentEmail,
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 28),

            Text('Participó en el evento:'),

            const SizedBox(height: 10),

            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Text('Fecha de término: ${_fmt(widget.endAt)}'),

            const SizedBox(height: 28),

            /// ⬇️ BOTÓN PDF
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Descargar PDF'),
              onPressed: _downloadPdf,
            ),

            const SizedBox(height: 24),

            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 12),

            const Text(
              'Esta constancia es válida para fines académicos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime? d) =>
      d == null ? 'No disponible' : '${d.day}/${d.month}/${d.year}';
}
