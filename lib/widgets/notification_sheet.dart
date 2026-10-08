import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/devtrack_models.dart';

class NotificationSheet extends StatefulWidget {
  const NotificationSheet({
    super.key,
  });

  @override
  State<NotificationSheet> createState() {
    return _NotificationSheetState();
  }
}

class _NotificationSheetState extends State<NotificationSheet> {
  List<AppNotification> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // loading notifications when the sheet opens
    loadNotifications();
  }

  // getting notifications from the database
  Future<void> loadNotifications() async {
    final savedNotifications =
    await DatabaseHelper.instance.getNotifications();

    if (!mounted) {
      return;
    }

    setState(() {
      notifications = savedNotifications;
      isLoading = false;
    });
  }

  // marking one notification as read
  Future<void> markAsRead(
      AppNotification notification,
      ) async {
    if (notification.id == null || !notification.unread) {
      return;
    }

    await DatabaseHelper.instance.markNotificationAsRead(
      notification.id!,
    );

    await loadNotifications();
  }

  // marking every notification as read
  Future<void> markAllAsRead() async {
    await DatabaseHelper.instance.markAllNotificationsAsRead();

    await loadNotifications();
  }

  // deleting one notification
  Future<void> deleteNotification(
      AppNotification notification,
      ) async {
    if (notification.id == null) {
      return;
    }

    await DatabaseHelper.instance.deleteNotification(
      notification.id!,
    );

    await loadNotifications();
  }

  // getting the notification icon
  IconData getNotificationIcon(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.overdue:
        return Icons.error_outline;

      case NotificationKind.atRisk:
        return Icons.warning_amber;

      case NotificationKind.completed:
        return Icons.check_circle_outline;

      case NotificationKind.assigned:
        return Icons.assignment_ind_outlined;
    }
  }

  // getting the notification color
  Color getNotificationColor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.overdue:
        return Colors.red;

      case NotificationKind.atRisk:
        return Colors.orange;

      case NotificationKind.completed:
        return Colors.green;

      case NotificationKind.assigned:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 10),

            // showing the line above the sheet
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  TextButton(
                    onPressed: notifications.isEmpty
                        ? null
                        : markAllAsRead,
                    child: const Text('Mark all as read'),
                  ),
                ],
              ),
            ),

            const Divider(),

            Expanded(
              child: buildNotificationContent(),
            ),
          ],
        ),
      ),
    );
  }

  // creating the notification content
  Widget buildNotificationContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: notifications.length,
      separatorBuilder: (context, index) {
        return const Divider(height: 1);
      },
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final color = getNotificationColor(
          notification.kind,
        );

        return Dismissible(
          key: ValueKey(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 25),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) {
            deleteNotification(notification);
          },
          child: ListTile(
            onTap: () {
              markAsRead(notification);
            },
            tileColor: notification.unread
                ? color.withValues(alpha: 0.08)
                : null,
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                getNotificationIcon(notification.kind),
                color: color,
              ),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.unread
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${notification.subtitle}\n'
                    '${notification.timeLabel}',
              ),
            ),
            isThreeLine: true,
            trailing: notification.unread
                ? Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            )
                : null,
          ),
        );
      },
    );
  }
}