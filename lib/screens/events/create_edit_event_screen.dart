import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/event_catalog.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class CreateEditEventScreen extends StatefulWidget {
  final EventModel? initial;

  const CreateEditEventScreen({super.key, this.initial});

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

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> save() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final title = titleCtrl.text.trim();
      final desc = descCtrl.text.trim();
      final loc = locationCtrl.text.trim();
      final cap = int.tryParse(capacityCtrl.text.trim()) ?? 0;

      if (title.isEmpty || desc.isEmpty || loc.isEmpty) {
        throw Exception('Completa título, descripción y ubicación.');
      }
      if (category == null || subcategory == null) {
        throw Exception('Selecciona categoría y tipo de evento.');
      }
      if (startAt == null || endAt == null) {
        throw Exception('Selecciona fecha y hora.');
      }
      if (!endAt!.isAfter(startAt!)) {
        throw Exception('La hora fin debe ser posterior a la hora inicio.');
      }
      if (cap <= 0) {
        throw Exception('El cupo debe ser mayor a 0.');
      }

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

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = eventCatalog.keys.toList();
    final subcats =
        category == null ? <String>[] : (eventCatalog[category] ?? <String>[]);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Crear evento' : 'Editar evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ---------- IMAGEN ----------
            GestureDetector(
              onTap: loading ? null : pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                  image: imageFile != null
                      ? DecorationImage(
                          image: FileImage(imageFile!),
                          fit: BoxFit.cover,
                        )
                      : widget.initial?.imageUrl != null
                          ? DecorationImage(
                              image:
                                  NetworkImage(widget.initial!.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: imageFile == null &&
                        widget.initial?.imageUrl == null
                    ? const Center(
                        child: Text('Agregar imagen'),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // ---------- FORM ----------
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                category = v;
                subcategory = null;
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: subcategory,
              decoration: const InputDecoration(
                labelText: 'Tipo de evento',
                border: OutlineInputBorder(),
              ),
              items: subcats
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s),
                      ))
                  .toList(),
              onChanged:
                  category == null ? null : (v) => setState(() => subcategory = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cupo máximo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            final dt = await pickDateTime(startAt);
                            if (dt != null) setState(() => startAt = dt);
                          },
                    child: Text(
                      startAt == null
                          ? 'Inicio'
                          : 'Inicio: ${startAt!.toString()}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            final dt = await pickDateTime(endAt);
                            if (dt != null) setState(() => endAt = dt);
                          },
                    child: Text(
                      endAt == null
                          ? 'Fin'
                          : 'Fin: ${endAt!.toString()}',
                    ),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : save,
                child: Text(loading ? 'Guardando...' : 'Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
