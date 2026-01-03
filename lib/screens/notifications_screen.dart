import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../widgets/notification_tile.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final notificationService = NotificationService();

    return StreamBuilder(
      stream: userService.streamMe(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userId = userSnap.data!.uid;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: const Text(
              'Notificaciones',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          body: StreamBuilder<List<AppNotification>>(
            stream:
                notificationService.getMyNotifications(userId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final notifications = snap.data!;

              if (notifications.isEmpty) {
                return const _EmptyNotificationsState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, i) {
                  final n = notifications[i];

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 14),
                    child: _AnimatedNotificationTile(
                      notification: n,
                      onTap: () {
                        if (!n.read) {
                          notificationService
                              .markAsRead(n.id);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
class _AnimatedNotificationTile extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _AnimatedNotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  State<_AnimatedNotificationTile> createState() =>
      _AnimatedNotificationTileState();
}

class _AnimatedNotificationTileState
    extends State<_AnimatedNotificationTile> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) {
          setState(() => pressed = false);
          widget.onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.notification.read
                ? Colors.white
                : Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: NotificationTile(
            notification: widget.notification,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}
class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

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
              Icons.notifications_none_rounded,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes notificaciones',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando ocurra algo importante, lo verás aquí.',
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
