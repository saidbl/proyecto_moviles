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
                color:
                    widget.theme.colorScheme.primary.withOpacity(0.1),
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

            /// 📄 TEXTO
            Text(
              'Se hace constar que:',
              style: widget.theme.textTheme.bodyMedium,
            ),

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
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Participó en el evento:',
              style: widget.theme.textTheme.bodyMedium,
            ),

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

            Text(
              'Fecha de término: ${_fmt(widget.endAt)}',
              style: widget.theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 36),

            /// 🖋 FOOTER
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
