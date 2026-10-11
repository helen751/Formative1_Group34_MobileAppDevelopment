import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/devtrack_models.dart';
import '../models/project_task.dart';
import '../theme/devtrack_theme.dart';
import '../widgets/dark_button.dart';
import '../widgets/filter_pill.dart';
import '../widgets/status_badge.dart';
import 'create_task_page.dart';
import 'task_details_page.dart';

// the ways the task list can be sorted
enum TaskSort {
  dueDate('Due date'),
  newest('Newest first'),
  priority('Priority');

  const TaskSort(this.label);

  final String label;
}

// tasks tab: search, filter and manage every task
class TaskListPage extends StatefulWidget {
  const TaskListPage({
    super.key,
    this.onNewTask,
    this.onChanged,
    this.refreshCount = 0,
  });

  // opening the create task page (handled by the home shell)
  final VoidCallback? onNewTask;

  // telling the other tabs that a task was changed here
  final VoidCallback? onChanged;

  // goes up every time a task changes somewhere else, so the list reloads
  final int refreshCount;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final _searchController = TextEditingController();

  // null until the first load finishes
  List<ProjectTask>? _tasks;
  List<Member> _members = [];
  bool _loadFailed = false;

  String _query = '';

  // null shows every status
  SlaStatus? _statusFilter;

  // null shows every member
  String? _assigneeFilter;
  TaskSort _sort = TaskSort.dueDate;

  @override
  void initState() {
    super.initState();

    _loadTasks();
  }

  @override
  void didUpdateWidget(TaskListPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // reloading after a task was added or changed on another tab
    if (widget.refreshCount != oldWidget.refreshCount) {
      _loadTasks();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // getting the tasks and members from the database
  Future<void> _loadTasks() async {
    try {
      final tasks = await DatabaseHelper.instance.getTasks();
      final members = await DatabaseHelper.instance.getMembers();

      if (!mounted) {
        return;
      }

      setState(() {
        _tasks = tasks;
        _members = members;
        _loadFailed = false;
      });
    } catch (error) {
      debugPrint('Could not load tasks: $error');

      if (!mounted) {
        return;
      }

      setState(() => _loadFailed = true);
    }
  }

  // reloading this page and letting the other tabs know
  Future<void> _afterChange() async {
    await _loadTasks();
    widget.onChanged?.call();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // opening the details page of a task
  Future<void> _openDetails(ProjectTask task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailsPage(task: task)),
    );

    // the task may have been edited, completed or deleted there
    await _afterChange();
  }

  // opening the edit form
  Future<void> _editTask(ProjectTask task) async {
    final updated = await Navigator.push<ProjectTask>(
      context,
      MaterialPageRoute(builder: (_) => CreateTaskPage(task: task)),
    );

    if (updated == null || !mounted) {
      return;
    }

    await _afterChange();
    _showMessage('"${updated.title}" updated');
  }

  // marking a task as completed, or opening it again
  Future<void> _toggleCompleted(ProjectTask task) async {
    final completed = !task.isCompleted;

    try {
      await DatabaseHelper.instance.updateTaskCompletion(task.id!, completed);
    } catch (error) {
      _showMessage('Could not update the task. Please try again.');
      return;
    }

    if (!mounted) {
      return;
    }

    await _afterChange();
    _showMessage(completed ? 'Task marked as completed' : 'Task reopened');
  }

  // asking before deleting a task
  Future<void> _deleteTask(ProjectTask task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task'),
          content: Text('Do you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: DevTrackColors.overdue),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await DatabaseHelper.instance.deleteTask(task.id!);
    } catch (error) {
      _showMessage('Could not delete the task. Please try again.');
      return;
    }

    if (!mounted) {
      return;
    }

    await _afterChange();
    _showMessage('Task deleted');
  }

  // opening the sort and member filter sheet
  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<(TaskSort, String?)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DevTrackColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FilterSheet(
        sort: _sort,
        assignee: _assigneeFilter,
        members: _members,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _sort = result.$1;
      _assigneeFilter = result.$2;
    });
  }

  // the tasks that match the search, status chip and member filter
  List<ProjectTask> _visibleTasks(List<ProjectTask> tasks) {
    final query = _query.trim().toLowerCase();

    final visible = tasks.where((task) {
      if (_statusFilter != null && task.status != _statusFilter) {
        return false;
      }

      if (_assigneeFilter != null && task.assignee != _assigneeFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return task.title.toLowerCase().contains(query) ||
          task.category.toLowerCase().contains(query) ||
          task.assignee.toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case TaskSort.dueDate:
        visible.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      case TaskSort.newest:
        visible.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      case TaskSort.priority:
        // high first, then the closest deadline
        visible.sort((a, b) {
          final byPriority = b.priority.index.compareTo(a.priority.index);
          return byPriority != 0 ? byPriority : a.dueDate.compareTo(b.dueDate);
        });
    }

    return visible;
  }

  // the initials shown in a task's avatar
  String _initialsFor(String assignee) {
    for (final member in _members) {
      if (member.shortName == assignee) {
        return member.initials;
      }
    }

    return assignee.isEmpty ? '?' : assignee[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadTasks,
                  color: DevTrackColors.ink,
                  backgroundColor: DevTrackColors.surface,
                  child: _buildList(),
                ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 16,
            child: _AddButton(onPressed: widget.onNewTask),
          ),
        ],
      ),
    );
  }

  // title, search field, filter button and status chips
  Widget _buildHeader() {
    final tasks = _tasks ?? const <ProjectTask>[];
    final filtersOn = _assigneeFilter != null || _sort != TaskSort.dueDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tasks',
            style: TextStyle(
              color: DevTrackColors.ink,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${tasks.length} tasks · ${tasks.countOf(SlaStatus.completed)} completed',
            style: const TextStyle(color: DevTrackColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: const TextStyle(color: DevTrackColors.muted),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: DevTrackColors.muted,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(
                              Icons.close,
                              color: DevTrackColors.muted,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: DevTrackColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: DevTrackColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: DevTrackColors.ink,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // dark when a sort or member filter is on
              Material(
                color: filtersOn ? DevTrackColors.ink : DevTrackColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: filtersOn
                        ? DevTrackColors.ink
                        : DevTrackColors.border,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openFilterSheet,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.tune_rounded,
                      semanticLabel: 'Sort and filter',
                      color: filtersOn
                          ? DevTrackColors.mint
                          : DevTrackColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // scrolls sideways so every chip fits on small phones
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterPill(
                  label: 'All  ${tasks.length}',
                  selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                ),
                for (final status in SlaStatus.values) ...[
                  const SizedBox(width: 8),
                  FilterPill(
                    label: '${status.label}  ${tasks.countOf(status)}',
                    selected: _statusFilter == status,
                    onTap: () => setState(() => _statusFilter = status),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildList() {
    final tasks = _tasks;

    if (tasks == null) {
      return _loadFailed
          ? const _ListMessage(
              icon: Icons.error_outline,
              text: 'Could not load tasks. Pull down to try again.',
            )
          : const Center(
              child: CircularProgressIndicator(color: DevTrackColors.ink),
            );
    }

    final visible = _visibleTasks(tasks);

    if (visible.isEmpty) {
      return _ListMessage(
        icon: Icons.inbox_outlined,
        text: tasks.isEmpty
            ? 'No tasks yet. Tap + to add the first one.'
            : 'No tasks match your search or filters.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      // extra bottom space so the + button never covers the last card
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = visible[index];

        return _TaskCard(
          task: task,
          initials: _initialsFor(task.assignee),
          onTap: () => _openDetails(task),
          onEdit: () => _editTask(task),
          onToggleCompleted: () => _toggleCompleted(task),
          onDelete: () => _deleteTask(task),
        );
      },
    );
  }
}

// actions in a task card's menu
enum _TaskAction { edit, toggleCompleted, delete }

// one task: title, category, assignee, due date, priority and SLA badge
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.initials,
    required this.onTap,
    required this.onEdit,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  final ProjectTask task;
  final String initials;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = task.status;

    return Material(
      color: DevTrackColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: DevTrackColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: DevTrackColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.category,
                      style: const TextStyle(
                        color: DevTrackColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Avatar(initials: initials),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            task.dueDateLabel,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DevTrackColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.flag_rounded,
                          size: 15,
                          color: task.priority.color,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          task.priority.label,
                          style: TextStyle(
                            color: task.priority.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<_TaskAction>(
                    tooltip: 'Task actions',
                    icon: const Icon(
                      Icons.more_vert,
                      color: DevTrackColors.muted,
                    ),
                    color: DevTrackColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _TaskAction.edit:
                          onEdit();
                        case _TaskAction.toggleCompleted:
                          onToggleCompleted();
                        case _TaskAction.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: _TaskAction.edit,
                        child: _MenuRow(
                          icon: Icons.edit_outlined,
                          label: 'Edit task',
                        ),
                      ),
                      PopupMenuItem(
                        value: _TaskAction.toggleCompleted,
                        child: _MenuRow(
                          icon: task.isCompleted
                              ? Icons.restart_alt
                              : Icons.check_circle_outline,
                          label: task.isCompleted
                              ? 'Reopen task'
                              : 'Mark as completed',
                        ),
                      ),
                      const PopupMenuItem(
                        value: _TaskAction.delete,
                        child: _MenuRow(
                          icon: Icons.delete_outline,
                          label: 'Delete task',
                          color: DevTrackColors.overdue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: StatusBadge(label: status.label, color: status.color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// icon and text inside the card menu
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.color = DevTrackColors.ink,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

// mint circle with the assignee's initials
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: DevTrackColors.mint,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: DevTrackColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// round + button for adding a task
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: DevTrackColors.ink,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              Icons.add,
              size: 26,
              color: DevTrackColors.mint,
              semanticLabel: 'Add task',
            ),
          ),
        ),
      ),
    );
  }
}

// message shown when the list is empty or failed to load
class _ListMessage extends StatelessWidget {
  const _ListMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    // a ListView so pull to refresh still works
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      children: [
        Icon(icon, size: 44, color: DevTrackColors.muted),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: DevTrackColors.muted, fontSize: 14),
        ),
      ],
    );
  }
}

// bottom sheet for choosing the sort order and a member
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.sort,
    required this.assignee,
    required this.members,
  });

  final TaskSort sort;
  final String? assignee;
  final List<Member> members;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TaskSort _sort = widget.sort;
  late String? _assignee = widget.assignee;

  static const _heading = TextStyle(
    color: DevTrackColors.ink,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DevTrackColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sort & filter',
                    style: TextStyle(
                      color: DevTrackColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _sort = TaskSort.dueDate;
                    _assignee = null;
                  }),
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: DevTrackColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Sort by', style: _heading),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sort in TaskSort.values)
                  FilterPill(
                    label: sort.label,
                    selected: _sort == sort,
                    onTap: () => setState(() => _sort = sort),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Assigned to', style: _heading),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterPill(
                  label: 'Everyone',
                  selected: _assignee == null,
                  onTap: () => setState(() => _assignee = null),
                ),
                for (final member in widget.members)
                  FilterPill(
                    label: member.shortName,
                    selected: _assignee == member.shortName,
                    onTap: () => setState(() => _assignee = member.shortName),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            DarkButton(
              label: 'Apply',
              icon: Icons.check,
              onPressed: () => Navigator.pop(context, (_sort, _assignee)),
            ),
          ],
        ),
      ),
    );
  }
}
