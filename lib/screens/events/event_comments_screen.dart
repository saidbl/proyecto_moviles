import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventCommentsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final bool canComment;

  const EventCommentsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.canComment,
  });

  @override
  State<EventCommentsScreen> createState() => _EventCommentsScreenState();
}

class _EventCommentsScreenState extends State<EventCommentsScreen> {
  final ctrl = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (ctrl.text.trim().isEmpty) return;

    setState(() => sending = true);

    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;

    try {
      await db
          .collection('events')
          .doc(widget.eventId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Alumno',
        'text': ctrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ctrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('comments')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Comentarios · ${widget.eventTitle}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: commentsRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay comentarios'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    return Card(
                      child: ListTile(
                        title: Text(d['userName'] ?? ''),
                        subtitle: Text(d['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (widget.canComment)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu comentario...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: sending
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.send),
                      onPressed: sending ? null : _send,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
