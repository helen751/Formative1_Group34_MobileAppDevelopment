import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/devtrack_models.dart';
import '../models/project_task.dart';
import '../theme/devtrack_theme.dart';
import '../widgets/member_profile_sheet.dart';
import '../widgets/status_badge.dart';

/// Team tab: searchable list of member cards. Tapping a card opens that member's
/// profile sheet. Members and tasks come from the database; pull down to reload.
class TeamMembersPage extends StatefulWidget {
  const TeamMembersPage({super.key});

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  // Current text in the search field.
  String _query = '';

  // storing the members and tasks from the database
  // (members stays null until the first load finishes)
  List<Member>? _members;
  List<ProjectTask> _tasks = const [];
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();

    // loading the team when the page opens
    _load();
  }

  // getting the members and tasks from the database
  Future<void> _load() async {
    try {
      final members = await DatabaseHelper.instance.getMembers();
      final tasks = await DatabaseHelper.instance.getTasks();

      if (!mounted) {
        return;
      }

      setState(() {
        _members = members;
        _tasks = tasks;
        _loadFailed = false;
      });
    } catch (error) {
      debugPrint('Could not load the team: $error');

      if (!mounted) {
        return;
      }

      setState(() => _loadFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        color: DevTrackColors.ink,
        backgroundColor: DevTrackColors.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Text(
              'Team',
              style: TextStyle(
                color: DevTrackColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            ..._buildBody(),
          ],
        ),
      ),
    );
  }

  /// Everything under the "Team" title: a loader or error until the first load
  /// finishes, then the summary line, search field and member cards.
  List<Widget> _buildBody() {
    final members = _members;

    if (members == null) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Center(
            child: _loadFailed
                ? const Text(
                    'Could not load the team. Pull down to try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DevTrackColors.muted, fontSize: 14),
                  )
                : const CircularProgressIndicator(color: DevTrackColors.ink),
          ),
        ),
      ];
    }

    // A member "needs attention" when at least one of their tasks is overdue.
    final needsAttention = members
        .where((m) => m.tasksFrom(_tasks).countOf(SlaStatus.overdue) > 0)
        .length;

    // Search matches the name or role, ignoring case and surrounding spaces.
    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? members
        : members
            .where((m) =>
                m.name.toLowerCase().contains(q) ||
                m.role.toLowerCase().contains(q))
            .toList();

    return [
      const SizedBox(height: 12),
      Text(
        '${members.length} members · $needsAttention needs attention',
        style: const TextStyle(color: DevTrackColors.muted, fontSize: 13),
      ),
      const SizedBox(height: 12),
      _SearchField(onChanged: (value) => setState(() => _query = value)),
      for (final member in visible) ...[
        const SizedBox(height: 12),
        _MemberCard(
          member: member,
          tasks: member.tasksFrom(_tasks),
        ),
      ],
      if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Center(
            child: Text(
              members.isEmpty
                  ? 'No team members yet'
                  : 'No members match your search',
              style: const TextStyle(color: DevTrackColors.muted, fontSize: 14),
            ),
          ),
        ),
    ];
  }
}

/// Rounded search box with a magnifier icon.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: DevTrackColors.border),
    );

    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: DevTrackColors.ink, fontSize: 14),
      decoration: const InputDecoration(
        hintText: 'Search by name or role',
        hintStyle: TextStyle(color: DevTrackColors.muted, fontSize: 14),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 14, right: 10),
          child: Icon(Icons.search, size: 20, color: DevTrackColors.muted),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: DevTrackColors.surface,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: DevTrackColors.ink),
        ),
      ),
    );
  }
}

/// Card with avatar, name, role, an overdue badge (only when needed) and a
/// progress bar.
class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.tasks});

  final Member member;
  final List<ProjectTask> tasks;

  @override
  Widget build(BuildContext context) {
    final overdue = tasks.countOf(SlaStatus.overdue);

    return Material(
      color: DevTrackColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: DevTrackColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            showMemberProfileSheet(context, member: member, tasks: tasks),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: DevTrackColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      member.initials,
                      style: const TextStyle(
                        color: DevTrackColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            color: DevTrackColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.role,
                          style: const TextStyle(
                            color: DevTrackColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (overdue > 0) ...[
                    const SizedBox(width: 14),
                    StatusBadge(
                      label: '$overdue overdue',
                      color: DevTrackColors.overdue,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              _ProgressBar(value: tasks.progress),
              const SizedBox(height: 14),
              DefaultTextStyle(
                style: const TextStyle(
                  color: DevTrackColors.muted,
                  fontSize: 12.5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}'),
                    Text('${tasks.doneCount} done'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin bar showing [value] (0 to 1) of completed tasks: dark fill on a faint
/// mint track.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 8,
        color: DevTrackColors.mint.withValues(alpha: 0.4),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          heightFactor: 1,
          child: const ColoredBox(color: DevTrackColors.ink),
        ),
      ),
    );
  }
}
