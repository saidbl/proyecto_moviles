import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/event_service.dart';

class ScanAttendanceScreen extends StatefulWidget {
  final String eventId;

  const ScanAttendanceScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<ScanAttendanceScreen> createState() =>
      _ScanAttendanceScreenState();
}

class _ScanAttendanceScreenState
    extends State<ScanAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final eventService = EventService();
  bool processing = false;

  late final AnimationController _controller;
  late final Animation<double> _scanLine;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLine = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(
    BuildContext context,
    BarcodeCapture capture,
  ) async {
    if (processing) return;

    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    setState(() => processing = true);

    try {
      final data = jsonDecode(raw);
      final qrEventId = data['eventId'];
      final userId = data['userId'];

      if (qrEventId != widget.eventId) {
        throw Exception('Este QR no pertenece a este evento');
      }

      await eventService.markAttendanceByOrganizer(
        eventId: widget.eventId,
        userId: userId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asistencia registrada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Escanear asistencia',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          /// 📸 CÁMARA
          MobileScanner(
            onDetect: (capture) =>
                _onDetect(context, capture),
          ),

          /// 🟦 OVERLAY OSCURO
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          /// 🎯 MARCO DE ESCANEO
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),

                  /// 🔵 LÍNEA ANIMADA
                  AnimatedBuilder(
                    animation: _scanLine,
                    builder: (context, _) {
                      return Positioned(
                        top: _scanLine.value * 260,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          /// 🧠 TEXTO DE AYUDA
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  'Coloca el código QR dentro del marco',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La asistencia se registrará automáticamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                if (processing) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
