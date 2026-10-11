import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/devtrack_models.dart';
import '../models/project_task.dart';
import '../theme/devtrack_theme.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    super.key,
    this.refreshCount = 0,
  });

  // reloading after a task changes
  final int refreshCount;

  @override
  State<StatisticsPage> createState() {
    return _StatisticsPageState();
  }
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<ProjectTask>? _tasks;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();

    // loading tasks when the page opens
    _loadTasks();
  }

  @override
  void didUpdateWidget(StatisticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // reloading after a task changes
    if (widget.refreshCount != oldWidget.refreshCount) {
      _loadTasks();
    }
  }

  // getting tasks from the database
  Future<void> _loadTasks() async {
    try {
      final savedTasks =
      await DatabaseHelper.instance.getTasks();

      if (!mounted) {
        return;
      }

      setState(() {
        _tasks = savedTasks;
        _loadFailed = false;
      });
    } catch (error) {
      debugPrint('Could not load statistics: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _tasks;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadTasks,
        color: DevTrackColors.ink,
        backgroundColor: DevTrackColors.surface,
        child: tasks == null
            ? _buildLoadingContent()
            : _buildStatistics(tasks),
      ),
    );
  }

  // showing the loading or error message
  Widget _buildLoadingContent() {
    if (_loadFailed) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(30),
        children: const [
          SizedBox(height: 200),
          Icon(
            Icons.error_outline,
            size: 55,
            color: DevTrackColors.overdue,
          ),
          SizedBox(height: 12),
          Text(
            'Could not load statistics.\nPull down to try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DevTrackColors.muted,
              fontSize: 15,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 260),
        Center(
          child: CircularProgressIndicator(
            color: DevTrackColors.ink,
          ),
        ),
      ],
    );
  }

  // creating the statistics page
  Widget _buildStatistics(List<ProjectTask> tasks) {
    final total = tasks.length;

    final completed = tasks.where((task) {
      return task.isCompleted;
    }).length;

    final open = total - completed;

    final overdue = tasks.where((task) {
      return task.status == SlaStatus.overdue;
    }).length;

    final atRisk = tasks.where((task) {
      return task.status == SlaStatus.atRisk;
    }).length;

    final onTrack = tasks.where((task) {
      return task.status == SlaStatus.onTrack;
    }).length;

    final progress = total == 0 ? 0.0 : completed / total;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100,),
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            color: DevTrackColors.ink,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Track the progress of your project.',
          style: TextStyle(
            color: DevTrackColors.muted,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 22),

        // showing the main task numbers
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total',
                value: total,
                icon: Icons.assignment_outlined,
                color: DevTrackColors.ink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Completed',
                value: completed,
                icon: Icons.check_circle_outline,
                color: DevTrackColors.completed,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Open',
                value: open,
                icon: Icons.pending_actions_outlined,
                color: DevTrackColors.atRisk,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // showing the completion progress
        _ProgressCard(
          completed: completed,
          total: total,
          progress: progress,
        ),

        const SizedBox(height: 18),

        // showing the SLA graph
        _SectionCard(
          title: 'SLA overview',
          child: Column(
            children: [
              _GraphBar(
                label: 'On Track',
                value: onTrack,
                total: total,
                color: DevTrackColors.onTrack,
              ),
              const SizedBox(height: 16),
              _GraphBar(
                label: 'At Risk',
                value: atRisk,
                total: total,
                color: DevTrackColors.atRisk,
              ),
              const SizedBox(height: 16),
              _GraphBar(
                label: 'Overdue',
                value: overdue,
                total: total,
                color: DevTrackColors.overdue,
              ),
              const SizedBox(height: 16),
              _GraphBar(
                label: 'Completed',
                value: completed,
                total: total,
                color: DevTrackColors.completed,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // showing tasks by stage
        _SectionCard(
          title: 'Tasks by stage',
          child: _StageGraph(
            tasks: tasks,
          ),
        ),

        const SizedBox(height: 18),

        // showing tasks by priority
        _SectionCard(
          title: 'Tasks by priority',
          child: _PriorityGraph(
            tasks: tasks,
          ),
        ),

        const SizedBox(height: 18),

        // showing progress for each member
        _SectionCard(
          title: 'Team progress',
          child: _TeamProgress(
            tasks: tasks,
          ),
        ),
      ],
    );
  }
}

// creating one main number card
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 16,
      ),
      decoration: devTrackCard(radius: 18),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 25,
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              color: DevTrackColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DevTrackColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// creating the completion progress card
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DevTrackColors.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            height: 95,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 95,
                  height: 95,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 11,
                    backgroundColor:
                    Colors.white.withOpacity(0.18),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(
                      DevTrackColors.mint,
                    ),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: DevTrackColors.mint,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Project progress',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$completed of $total tasks',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'completed',
                  style: TextStyle(
                    color: DevTrackColors.mint,
                    fontSize: 14,
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

// creating a section card
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: devTrackCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DevTrackColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// creating one horizontal graph bar
class _GraphBar extends StatelessWidget {
  const _GraphBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0
        ? 0.0
        : value / total;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: DevTrackColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
              color,
            ),
          ),
        ),
      ],
    );
  }
}

// creating the stage graph
class _StageGraph extends StatelessWidget {
  const _StageGraph({
    required this.tasks,
  });

  final List<ProjectTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final stage in TaskStage.values) ...[
          _GraphBar(
            label: stage.label,
            value: tasks.where((task) {
              return task.stage == stage;
            }).length,
            total: tasks.length,
            color: _stageColor(stage),
          ),
          if (stage != TaskStage.values.last)
            const SizedBox(height: 16),
        ],
      ],
    );
  }

  // getting the stage color
  Color _stageColor(TaskStage stage) {
    switch (stage) {
      case TaskStage.toDo:
        return DevTrackColors.muted;

      case TaskStage.inProgress:
        return DevTrackColors.atRisk;

      case TaskStage.done:
        return DevTrackColors.completed;
    }
  }
}

// creating the priority graph
class _PriorityGraph extends StatelessWidget {
  const _PriorityGraph({
    required this.tasks,
  });

  final List<ProjectTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final priority in TaskPriority.values) ...[
          _GraphBar(
            label: priority.label,
            value: tasks.where((task) {
              return task.priority == priority;
            }).length,
            total: tasks.length,
            color: priority.color,
          ),
          if (priority != TaskPriority.values.last)
            const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// creating progress for each team member
class _TeamProgress extends StatelessWidget {
  const _TeamProgress({
    required this.tasks,
  });

  final List<ProjectTask> tasks;

  @override
  Widget build(BuildContext context) {
    final members = <String>{};

    for (final task in tasks) {
      members.add(task.assignee);
    }

    if (members.isEmpty) {
      return const Text(
        'No team progress available',
        style: TextStyle(
          color: DevTrackColors.muted,
        ),
      );
    }

    final sortedMembers = members.toList()..sort();

    return Column(
      children: [
        for (final member in sortedMembers) ...[
          _memberProgress(member),
          if (member != sortedMembers.last)
            const SizedBox(height: 18),
        ],
      ],
    );
  }

  // creating one member progress row
  Widget _memberProgress(String member) {
    final memberTasks = tasks.where((task) {
      return task.assignee == member;
    }).toList();

    final completed = memberTasks.where((task) {
      return task.isCompleted;
    }).length;

    final total = memberTasks.length;

    return _GraphBar(
      label: '$member  ($completed/$total)',
      value: completed,
      total: total,
      color: DevTrackColors.onTrack,
    );
  }
}