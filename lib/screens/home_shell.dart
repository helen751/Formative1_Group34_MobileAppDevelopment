import 'package:flutter/material.dart';

import '../models/project_task.dart';
import '../theme/devtrack_theme.dart';
import 'create_task_page.dart';
import 'dashboard.dart';
import 'team_members_page.dart';

/// Main app shell with the DevTrack bottom navigation.
///
/// Tasks and Stats are placeholders until those modules are plugged in.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// Position of the Tasks tab, used by the dashboard's "See all" link.
  static const _tasksTab = 1;

  int _index = 0;

  // telling the dashboard to reload its tasks
  int _refreshCount = 0;

  void _select(int index) => setState(() => _index = index);

  // opening the create task page
  Future<void> _onNewTask() async {
    final created = await Navigator.of(context).push<ProjectTask>(
      MaterialPageRoute(builder: (_) => const CreateTaskPage()),
    );

    if (created == null || !mounted) {
      return;
    }

    setState(() => _refreshCount++);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${created.title}" assigned to ${created.assignee}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps every tab alive, so filters and search text survive
      // switching tabs.
      body: IndexedStack(
        index: _index,
        children: [
          DashboardPage(
            onSeeAll: () => _select(_tasksTab),
            onNewTask: _onNewTask,
            refreshCount: _refreshCount,
          ),
          const _ComingSoon(title: 'Tasks'),
          const TeamMembersPage(),
          const _ComingSoon(title: 'Stats'),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: _index, onTap: _select),
    );
  }
}

/// Bottom navigation bar with one [_NavItem] per tab.
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.grid_view_rounded, label: 'Dashboard'),
    (icon: Icons.checklist_rounded, label: 'Tasks'),
    (icon: Icons.people_outline_rounded, label: 'Team'),
    (icon: Icons.bar_chart_rounded, label: 'Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DevTrackColors.surface,
        border: Border(top: BorderSide(color: DevTrackColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].icon,
                    label: _items[i].label,
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab: the selected tab gets a mint pill behind its icon and a bold label.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? DevTrackColors.mint : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? DevTrackColors.ink : DevTrackColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? DevTrackColors.ink : DevTrackColors.muted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stand-in for tabs whose module isn't plugged in yet.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title – coming soon',
        style: const TextStyle(color: DevTrackColors.muted, fontSize: 16),
      ),
    );
  }
}
