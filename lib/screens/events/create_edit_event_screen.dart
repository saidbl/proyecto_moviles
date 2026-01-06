import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/event_catalog.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class CreateEditEventScreen extends StatefulWidget {
  final EventModel? initial;
  final VoidCallback? onEventSaved; 

  const CreateEditEventScreen({
    super.key, 
    this.initial, 
    this.onEventSaved,
  });

  @override
  State<CreateEditEventScreen> createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<CreateEditEventScreen> {
  final service = EventService();

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final capacityCtrl = TextEditingController(text: '50');

  final picker = ImagePicker();
  File? imageFile;

  String? category;
  String? subcategory;

  DateTime? startAt;
  DateTime? endAt;

  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    if (e != null) {
      titleCtrl.text = e.title;
      descCtrl.text = e.description;
      locationCtrl.text = e.location;
      capacityCtrl.text = e.capacity.toString();
      category = e.category;
      subcategory = e.subcategory;
      startAt = e.startAt;
      endAt = e.endAt;
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    locationCtrl.dispose();
    capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (x != null) {
      setState(() => imageFile = File(x.path));
    }
  }

  Future<DateTime?> pickDateTime(DateTime? current) async {
    final now = DateTime.now();
    final base = current ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  void _clearForm() {
    titleCtrl.clear();
    descCtrl.clear();
    locationCtrl.clear();
    capacityCtrl.text = '50';
    setState(() {
      imageFile = null;
      startAt = null;
      endAt = null;
      category = null;
      subcategory = null;
      error = null;
    });
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();

    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final loc = locationCtrl.text.trim();
    final cap = int.tryParse(capacityCtrl.text.trim()) ?? 0;

    if (title.isEmpty || desc.isEmpty || loc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa título, descripción y ubicación.')),
      );
      return;
    }
    if (category == null || subcategory == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona categoría y tipo de evento.')),
      );
      return;
    }
    if (startAt == null || endAt == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y hora.')),
      );
      return;
    }
    if (!endAt!.isAfter(startAt!)) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora fin debe ser posterior a la de inicio.')),
      );
      return;
    }
    if (cap <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El cupo debe ser mayor a 0.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (widget.initial == null) {
        await service.createEvent(
          title: title,
          description: desc,
          category: category!,
          subcategory: subcategory!,
          location: loc,
          startAt: startAt!,
          endAt: endAt!,
          capacity: cap,
          imageFile: imageFile,
        );
      } else {
        await service.updateEvent(
          eventId: widget.initial!.id,
          title: title,
          description: desc,
          category: category!,
          subcategory: subcategory!,
          location: loc,
          startAt: startAt!,
          endAt: endAt!,
          capacity: cap,
          imageFile: imageFile,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(); // Cierra loading

        if (widget.initial == null) {
          // MODO CREAR
          _clearForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Evento creado con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onEventSaved?.call(); 
        } else {
          // MODO EDITAR
          Navigator.of(context).pop(); 
        }
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cierra loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =========================================================
  // LOGICA DE ELIMINACIÓN / CANCELACIÓN
  // =========================================================

  Future<void> _handleDeleteOptions() async {
    final event = widget.initial;
    if (event == null) return;

    final bool isFinished = event.endAt.isBefore(DateTime.now());
    final bool isActive = event.isActive ?? true;

    // CASO 1: Finalizado o Cancelado -> SOLO BORRAR
    if (isFinished || !isActive) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Eliminar registro permanentemente?'),
          content: Text(
            isFinished 
              ? 'El evento ya finalizó. Si lo eliminas, desaparecerá de tu historial y de la base de datos para siempre.'
              : 'El evento ya está cancelado. ¿Deseas borrarlo definitivamente de la base de datos?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ELIMINAR TODO', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _performDelete(event.id);
      }
      return;
    }

    // CASO 2: Activo -> CANCELAR O BORRAR
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gestionar evento activo'),
        content: const Text(
          'Selecciona una acción:\n\n'
          'SOLO CANCELAR (Recomendado): \n'
          'El evento se marca como "Cancelado".\n\n'
          'ELIMINAR: \n'
          'Borra el evento permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); 
              _confirmCancel(event.id);
            },
            child: const Text('Solo Cancelar', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(event.id);
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Helpers definidos dentro de la clase ---

  Future<void> _performDelete(String id) async {
    await _performAction(
      () => service.deleteEvent(id), 
      'Evento eliminado permanentemente'
    );
  }

  Future<void> _confirmCancel(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Confirmar cancelación?'),
        content: const Text(
          'Al cancelar, el evento pasará a estado INACTIVO.\n'
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _performAction(
        () => service.cancelEvent(id), 
        'Evento cancelado (Inactivo)'
      );
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Estás absolutamente seguro?'),
        content: const Text(
          'Esta acción NO se puede deshacer.\n'
          'Se borrarán el evento, los comentarios y los registros de asistencia.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('SÍ, BORRAR TODO', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _performDelete(id);
    }
  }

  Future<void> _performAction(Future<void> Function() action, String successMessage) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await action();
      
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        
        // Si estamos editando, cerramos la pantalla
        if (widget.initial != null) {
           Navigator.pop(context); 
        }

        widget.onEventSaved?.call(); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    // Si no tienes eventCatalog, define uno temporal o impórtalo
    // final eventCatalog = {'Académicos': ['Conferencia'], 'Deportivos': ['Partido']}; 
    
    final categories = eventCatalog.keys.toList();
    final subcats = category == null
        ? <String>[]
        : (eventCatalog[category] ?? <String>[]);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          widget.initial == null ? 'Crear evento' : 'Editar evento',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _ImagePickerCard(
              imageFile: imageFile,
              imageUrl: widget.initial?.imageUrl,
              onTap: loading ? null : pickImage,
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Información general',
              children: [
                _Input(titleCtrl, 'Título'),
                _Input(descCtrl, 'Descripción', maxLines: 4),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Clasificación',
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() {
                    category = v;
                    subcategory = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: subcategory,
                  decoration: const InputDecoration(labelText: 'Tipo de evento'),
                  items: subcats.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: category == null ? null : (v) => setState(() => subcategory = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Detalles',
              children: [
                _Input(locationCtrl, 'Ubicación'),
                _Input(capacityCtrl, 'Cupo máximo', keyboard: TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Inicio',
                        value: startAt,
                        onTap: () async {
                          final d = await pickDateTime(startAt);
                          if (d != null) setState(() => startAt = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateButton(
                        label: 'Fin',
                        value: endAt,
                        onTap: () async {
                          final d = await pickDateTime(endAt);
                          if (d != null) setState(() => endAt = d);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : save,
                child: Text(
                  loading ? 'Guardando…' : 'Guardar evento',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // BOTÓN DE GESTIÓN (CANCELAR / ELIMINAR)
            if (widget.initial != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: (widget.initial!.endAt.isBefore(DateTime.now()) || !(widget.initial!.isActive ?? true))
                          ? Colors.red 
                          : Colors.orange.shade800,
                    ),
                    foregroundColor: (widget.initial!.endAt.isBefore(DateTime.now()) || !(widget.initial!.isActive ?? true))
                          ? Colors.red 
                          : Colors.orange.shade800,
                  ),
                  icon: Icon(
                    (widget.initial!.endAt.isBefore(DateTime.now()) || !(widget.initial!.isActive ?? true))
                        ? Icons.delete_forever
                        : Icons.cancel_presentation,
                  ),
                  label: Text(
                    (widget.initial!.endAt.isBefore(DateTime.now()) || !(widget.initial!.isActive ?? true))
                        ? 'Eliminar evento finalizado/cancelado'
                        : 'Cancelar o Eliminar evento',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _handleDeleteOptions,
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// WIDGETS AUXILIARES (Para que no tengas errores de referencia)
// =========================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final int maxLines;
  final TextInputType? keyboard;
  const _Input(this.ctrl, this.label, {this.maxLines = 1, this.keyboard});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(
        value == null
            ? label
            : '$label: ${value!.day}/${value!.month}/${value!.year} '
              '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback? onTap;
  const _ImagePickerCard({this.imageFile, this.imageUrl, this.onTap});
  @override
  Widget build(BuildContext context) {
    final hasImage = imageFile != null || imageUrl != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.grey.shade200,
          image: imageFile != null
              ? DecorationImage(image: FileImage(imageFile!), fit: BoxFit.cover)
              : imageUrl != null
                  ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                  : null,
        ),
        child: !hasImage
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add_a_photo, size: 36),
                    SizedBox(height: 8),
                    Text('Agregar imagen'),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}