import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/devtrack_models.dart';
import '../theme/devtrack_theme.dart';
import '../widgets/filter_pill.dart';
import '../widgets/task_tile.dart';

import '../database/database_helper.dart';
import '../widgets/notification_sheet.dart';
import '../services/task_notification_service.dart';

/// Whose tasks the dashboard counts: the whole team or only the signed-in user.
enum _Scope { everyone, mine }

/// Dashboard tab: project progress, due counters, SLA overview and the tasks that
/// need attention. Owns its refresh, scope and filter state.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.onSeeAll, this.onNewTask});

  /// Called when "See all" is tapped (switches to the Tasks tab).
  final VoidCallback? onSeeAll;

  /// Called when the floating "New task" button is tapped.
  final VoidCallback? onNewTask;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  // Shared with the notifications sheet so reading items there clears the bell dot.
  // storing notifications from the database
  final _notifications =
  ValueNotifier<List<AppNotification>>([]);

  // Set to false when the user closes the alert banner.
  bool _showAlert = true;
  _Scope _scope = _Scope.everyone;

  /// Status filter for the "Needs attention" list; null shows all open tasks.
  SlaStatus? _filter;

  @override
  void dispose() {
    _notifications.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // loading notifications when the dashboard opens
    loadNotifications();
  }

  // getting notifications from the database
  Future<void> loadNotifications() async {
    final savedNotifications =
    await DatabaseHelper.instance.getNotifications();

    if (!mounted) {
      return;
    }

    _notifications.value = savedNotifications;
  }

  // opening the notification sheet
  Future<void> openNotifications() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return const NotificationSheet();
      },
    );

    // updating the red dot after closing the sheet
    await loadNotifications();
  }

  // Pull-to-refresh handler: the spinner stays until this future completes.
  // reloading tasks and notifications
  Future<void> _fetch() async {
    await TaskNotificationService.checkTaskDeadlines();
    await loadNotifications();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetch,
            color: DevTrackColors.ink,
            backgroundColor: DevTrackColors.surface,
            child: _buildContent(),
          ),
          // Floats over the content, just above the bottom navigation bar.
          Positioned(
            right: 20,
            bottom: 16,
            child: _NewTaskButton(onPressed: widget.onNewTask),
          ),
        ],
      ),
    );
  }

  /// The scrollable dashboard content. Everything is computed from [tasks], so
  /// switching the scope updates the ring, counters, SLA cards and list together.
  Widget _buildContent() {
    final List<Task> tasks = _scope == _Scope.mine
        ? mockTasks.where((t) => t.assignee == currentUserFirstName).toList()
        : mockTasks;
    final open = tasks.open;
    final overdue = tasks.countOf(SlaStatus.overdue);
    final atRisk = tasks.countOf(SlaStatus.atRisk);

    // Open tasks for the list, most urgent first and narrowed by the selected
    // chip. Completed tasks are never listed here.
    final visible = [
      for (final status in const [
        SlaStatus.overdue,
        SlaStatus.atRisk,
        SlaStatus.onTrack,
      ])
        if (_filter == null || _filter == status)
          ...open.where((t) => t.status == status),
    ];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<List<AppNotification>>(
            valueListenable: _notifications,
            builder: (context, items, _) {
              return _Header(
                name: currentUserFirstName,
                hasUnread: items.any((notification) {
                  return notification.unread;
                }),
                onBell: openNotifications,
              );
            },
          ),
          const SizedBox(height: 16),
          _ScopeToggle(
            scope: _scope,
            onChanged: (scope) => setState(() => _scope = scope),
          ),
          // Only worth showing while something actually needs attention.
          if (_showAlert && overdue + atRisk > 0) ...[
            const SizedBox(height: 16),
            _AlertBanner(
              message: '$overdue overdue · $atRisk at risk, review your tasks',
              onTap: openNotifications,
              onDismiss: () {
                setState(() {
                  _showAlert = false;
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          _ProgressCard(
            projectName: projectName,
            done: tasks.doneCount,
            total: tasks.length,
          ),
          const SizedBox(height: 16),
          _DueSummary(
            dueToday: tasks.dueTodayCount,
            dueThisWeek: tasks.dueThisWeekCount,
          ),
          const SizedBox(height: 16),
          const Text('SLA overview', style: _sectionTitle),
          const SizedBox(height: 16),
          _SlaGrid(tasks: tasks),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text('Needs attention', style: _sectionTitle),
              ),
              GestureDetector(
                onTap: widget.onSeeAll,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: DevTrackColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Two spaces before each count keep the label and number visually apart.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterPill(
                label: 'All  ${open.length}',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              FilterPill(
                label: 'Overdue  $overdue',
                selected: _filter == SlaStatus.overdue,
                onTap: () => setState(() => _filter = SlaStatus.overdue),
              ),
              FilterPill(
                label: 'At Risk  $atRisk',
                selected: _filter == SlaStatus.atRisk,
                onTap: () => setState(() => _filter = SlaStatus.atRisk),
              ),
            ],
          ),
          if (visible.isEmpty) ...[
            const SizedBox(height: 16),
            _EmptyState(filter: _filter),
          ] else
            for (final task in visible) ...[
              const SizedBox(height: 16),
              TaskTile(
                task: task,
                subtitle: '${task.dueLabel} · ${task.assignee}',
              ),
            ],
        ],
      ),
    );
  }
}

/// Heading style for "SLA overview" and "Needs attention".
const _sectionTitle = TextStyle(
  color: DevTrackColors.ink,
  fontSize: 18,
  fontWeight: FontWeight.bold,
);

/// Logo, greeting and notification bell. The bell shows a red dot while [hasUnread].
class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.hasUnread,
    required this.onBell,
  });

  final String name;
  final bool hasUnread;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _LogoMark(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(color: DevTrackColors.muted, fontSize: 14),
              ),
              Text(
                name,
                style: const TextStyle(
                  color: DevTrackColors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Notifications',
          child: GestureDetector(
            onTap: onBell,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: DevTrackColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 22,
                      color: DevTrackColors.ink,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      left: 28,
                      top: 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: DevTrackColors.overdue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DevTrackColors.mint,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The app icon, cropped from the left part of images/devtrack_logo.png
/// (which also contains the "DevTrack" wordmark).
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  // Bounds of the icon mark inside the 1774x887 logo image.
  static const _markLeft = 135.0;
  static const _markTop = 240.0;
  static const _markSize = 415.0;
  static const _imageWidth = 1774.0;
  static const _imageHeight = 887.0;
  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    const scale = _size / _markSize;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.32),
      child: Container(
        width: _size,
        height: _size,
        color: DevTrackColors.ink,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -_markLeft * scale,
              top: -_markTop * scale,
              width: _imageWidth * scale,
              height: _imageHeight * scale,
              child: Image.asset('images/devtrack_logo.png', fit: BoxFit.fill),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Everyone / My tasks" segmented switch.
class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.scope, required this.onChanged});

  final _Scope scope;
  final ValueChanged<_Scope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: devTrackCard(radius: 16),
      child: Row(
        children: [
          Expanded(
            child: _ScopeOption(
              label: 'Everyone',
              selected: scope == _Scope.everyone,
              onTap: () => onChanged(_Scope.everyone),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ScopeOption(
              label: 'My tasks',
              selected: scope == _Scope.mine,
              onTap: () => onChanged(_Scope.mine),
            ),
          ),
        ],
      ),
    );
  }
}

/// One half of the toggle; the selected option is a dark pill.
class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? DevTrackColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? DevTrackColors.mint : DevTrackColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mint banner summarizing overdue and at-risk counts. Tapping it opens the
/// notifications; the X dismisses it.
class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.message,
    required this.onTap,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DevTrackColors.mint,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.campaign_outlined,
                  size: 22, color: DevTrackColors.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DevTrackColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close_rounded,
                    size: 18, color: DevTrackColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark card with the completion ring and "N of M tasks completed".
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.projectName,
    required this.done,
    required this.total,
  });

  final String projectName;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DevTrackColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _RingPainter(progress),
              child: Center(
                child: Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: DevTrackColors.mint,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project progress',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  projectName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$done of $total tasks completed',
                  style: const TextStyle(
                    color: DevTrackColors.mint,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the progress ring: a faint full circle with a mint arc on top that
/// starts at 12 o'clock.
class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  static const _stroke = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    canvas.drawArc(rect, 0, 2 * math.pi, false,
        paint..color = Colors.white.withValues(alpha: 0.18));
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false,
        paint..color = DevTrackColors.mint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// "Due today" and "This week" counters under the progress card.
class _DueSummary extends StatelessWidget {
  const _DueSummary({required this.dueToday, required this.dueThisWeek});

  final int dueToday;
  final int dueThisWeek;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DueTile(
            icon: Icons.schedule_rounded,
            color: DevTrackColors.overdue,
            tint: DevTrackColors.tint(DevTrackColors.overdue),
            count: dueToday,
            label: 'Due today',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DueTile(
            icon: Icons.calendar_today_outlined,
            color: DevTrackColors.ink,
            tint: DevTrackColors.ink.withValues(alpha: 0.08),
            count: dueThisWeek,
            label: 'This week',
          ),
        ),
      ],
    );
  }
}

/// Icon and counter tile. The text column is [Expanded] so long labels or large
/// accessibility text shrink with an ellipsis instead of overflowing.
class _DueTile extends StatelessWidget {
  const _DueTile({
    required this.icon,
    required this.color,
    required this.tint,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Color tint;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: devTrackCard(radius: 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20.9, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: DevTrackColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DevTrackColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2x2 grid of counters, one per [SlaStatus].
class _SlaGrid extends StatelessWidget {
  const _SlaGrid({required this.tasks});

  final List<Task> tasks;

  static const _icons = {
    SlaStatus.onTrack: Icons.trending_up_rounded,
    SlaStatus.atRisk: Icons.warning_amber_rounded,
    SlaStatus.overdue: Icons.error_outline_rounded,
    SlaStatus.completed: Icons.check_circle_outline_rounded,
  };

  Widget _card(SlaStatus status) => Expanded(
        child: _SlaCard(
          icon: _icons[status]!,
          color: status.color,
          count: tasks.countOf(status),
          label: status.label,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          _card(SlaStatus.onTrack),
          const SizedBox(width: 12),
          _card(SlaStatus.atRisk),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _card(SlaStatus.overdue),
          const SizedBox(width: 12),
          _card(SlaStatus.completed),
        ]),
      ],
    );
  }
}

/// A single SLA counter: tinted icon chip, big number and label.
class _SlaCard extends StatelessWidget {
  const _SlaCard({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: devTrackCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DevTrackColors.tint(color),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19.8, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            '$count',
            style: const TextStyle(
              color: DevTrackColors.ink,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: DevTrackColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the selected filter has no tasks.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final SlaStatus? filter;

  String get _message => switch (filter) {
        SlaStatus.overdue => 'No overdue tasks right now. Nice work.',
        SlaStatus.atRisk => 'No at-risk tasks right now. Nice work.',
        _ => 'No open tasks right now. Nice work.',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: devTrackCard(),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: DevTrackColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 30,
              color: DevTrackColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You’re all caught up',
            style: TextStyle(
              color: DevTrackColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DevTrackColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}


/// Floating pill that starts task creation.
class _NewTaskButton extends StatelessWidget {
  const _NewTaskButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DevTrackColors.ink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 20, color: DevTrackColors.mint),
                SizedBox(width: 8),
                Text(
                  'New task',
                  style: TextStyle(
                    color: DevTrackColors.mint,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


