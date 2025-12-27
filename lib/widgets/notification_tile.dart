import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        notification.read ? Icons.notifications : Icons.notifications_active,
        color: notification.read ? Colors.grey : Colors.blue,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight:
              notification.read ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(notification.message),
      onTap: onTap,
    );
  }
}
