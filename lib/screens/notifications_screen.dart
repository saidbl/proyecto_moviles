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
          appBar: AppBar(title: const Text('Notificaciones')),
          body: StreamBuilder<List<AppNotification>>(
            stream: notificationService.getMyNotifications(userId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snap.data!;

              if (notifications.isEmpty) {
                return const Center(
                  child: Text('No tienes notificaciones'),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, i) {
                  final n = notifications[i];
                  return NotificationTile(
                    notification: n,
                    onTap: () {
                      if (!n.read) {
                        notificationService.markAsRead(n.id);
                      }
                    },
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
