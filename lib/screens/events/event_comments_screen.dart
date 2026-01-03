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
        'userName':
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName
                : 'Alumno',
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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comentarios',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              widget.eventTitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          /// 💬 LISTA DE COMENTARIOS
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: commentsRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const _EmptyCommentsState();
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 12),
                      child: _CommentBubble(
                        userName: d['userName'] ?? 'Alumno',
                        text: d['text'] ?? '',
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ✍️ INPUT (SOLO SI PUEDE COMENTAR)
          if (widget.canComment)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                    12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Escribe tu comentario...',
                          filled: true,
                          fillColor:
                              Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration:
                          const Duration(milliseconds: 200),
                      child: sending
                          ? const Padding(
                              padding:
                                  EdgeInsets.all(8),
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                  Icons.send_rounded),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                              onPressed: _send,
                            ),
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
class _CommentBubble extends StatelessWidget {
  final String userName;
  final String text;

  const _CommentBubble({
    required this.userName,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 👤 NOMBRE DEL ALUMNO
          Text(
            userName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),

          /// 💬 TEXTO
          Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
class _EmptyCommentsState extends StatelessWidget {
  const _EmptyCommentsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no hay comentarios',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando los participantes comenten, aparecerán aquí.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

