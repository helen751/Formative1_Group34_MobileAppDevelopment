import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/devtrack_models.dart';
import '../models/project_task.dart';
import '../theme/devtrack_theme.dart';
import '../widgets/dark_button.dart';

// page for creating a new task or editing one
class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key, this.task, this.initialAssignee});

  // null when creating a new task
  final ProjectTask? task;

  // member picked already, e.g. from "Assign a task" on the team page
  final String? initialAssignee;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  static const _titleMinLength = 3;
  static const _titleMaxLength = 60;
  static const _descriptionMaxLength = 300;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // team members from the database, for the assign to dropdown
  List<Member> _members = [];

  String? _assignee;
  String? _category;
  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  TaskStage _stage = TaskStage.toDo;

  // showing a loader while saving
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    // filling the form with the task being edited
    final task = widget.task;

    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _assignee = task.assignee;
      _category = task.category;
      _dueDate = task.dueDate;
      _priority = task.priority;
      _stage = task.stage;
    } else {
      _assignee = widget.initialAssignee;
    }

    loadMembers();
  }

  // getting the team members from the database
  Future<void> loadMembers() async {
    try {
      final members = await DatabaseHelper.instance.getMembers();

      if (!mounted) {
        return;
      }

      setState(() => _members = members);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load team members')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // checking the title field
  String? _validateTitle(String? value) {
    final title = value?.trim() ?? '';

    if (title.isEmpty) {
      return 'Please enter a task title';
    }

    if (title.length < _titleMinLength) {
      return 'The title must be at least $_titleMinLength characters';
    }

    return null;
  }

  // checking the due date field
  String? _validateDueDate(DateTime? value) {
    if (value == null) {
      return 'Please choose a due date';
    }

    // allowing an old date when editing
    final keptOldDate = _isEditing && value == widget.task!.dueDate;

    if (!keptOldDate && value.isBefore(DateTime.now())) {
      return 'The due date must be in the future';
    }

    return null;
  }

  // opening the date picker, then the time picker
  Future<void> _pickDueDate(FormFieldState<DateTime> field) async {
    final now = DateTime.now();
    final current = _dueDate;

    final date = await showDatePicker(
      context: context,
      initialDate: current != null && current.isAfter(now) ? current : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (date == null || !mounted) {
      return;
    }

    // picking the time too for the at risk check
    final time = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay.fromDateTime(current)
          : const TimeOfDay(hour: 17, minute: 0),
    );

    if (time == null) {
      return;
    }

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() => _dueDate = picked);

    // removing the error message
    field.didChange(picked);
  }

  // saving the task to the database
  Future<void> _saveTask() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final task = ProjectTask(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      assignee: _assignee!,
      category: _category!,
      dueDate: _dueDate!,
      priority: _priority,
      stage: _stage,
      isCompleted: _stage == TaskStage.done,
    );

    try {
      final ProjectTask savedTask;

      if (_isEditing) {
        await DatabaseHelper.instance.updateTask(task);
        savedTask = task;
      } else {
        final id = await DatabaseHelper.instance.insertTask(task);
        savedTask = task.copyWith(id: id);

        // adding a notification for the new task
        await DatabaseHelper.instance.insertNotification(
          taskId: id,
          title: '${task.title} assigned to ${task.assignee}',
          subtitle: 'Due ${_formatDueDate(task.dueDate)}',
          timeLabel: 'Just now',
          kind: 'assigned',
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, savedTask);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the task. Please try again.'),
        ),
      );
    }
  }

  // checking if anything was changed
  bool get _hasChanges {
    final task = widget.task;

    if (task == null) {
      return _titleController.text.trim().isNotEmpty ||
          _descriptionController.text.trim().isNotEmpty ||
          _assignee != widget.initialAssignee ||
          _category != null ||
          _dueDate != null;
    }

    return _titleController.text.trim() != task.title ||
        _descriptionController.text.trim() != task.description ||
        _assignee != task.assignee ||
        _category != task.category ||
        _dueDate != task.dueDate ||
        _priority != task.priority ||
        _stage != task.stage;
  }

  // asking before leaving the page
  Future<void> _confirmDiscard() async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('What you have entered will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Discard',
                style: TextStyle(color: DevTrackColors.overdue),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDiscard == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isSaving || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: DevTrackColors.background,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            _isEditing ? 'Edit Task' : 'Create Task',
            style: const TextStyle(
              color: DevTrackColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const _FieldLabel('Task Title'),
                TextFormField(
                  controller: _titleController,
                  maxLength: _titleMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Enter task title'),
                  validator: _validateTitle,
                ),
                const SizedBox(height: 8),
                const _FieldLabel('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: _descriptionMaxLength,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Enter task description'),
                ),
                const SizedBox(height: 8),
                _IconField(
                  icon: Icons.folder_outlined,
                  iconColor: DevTrackColors.atRisk,
                  label: 'Category',
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    hint: const Text('Select category'),
                    decoration: _inputDecoration(null),
                    borderRadius: BorderRadius.circular(14),
                    items: [
                      for (final category in taskCategories)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      // keeping a category that is no longer in the list
                      if (_category != null &&
                          !taskCategories.contains(_category))
                        DropdownMenuItem(
                          value: _category,
                          child: Text(_category!),
                        ),
                    ],
                    onChanged: (value) => setState(() => _category = value),
                    validator: (value) =>
                        value == null ? 'Please choose a category' : null,
                  ),
                ),
                _IconField(
                  icon: Icons.person_outline_rounded,
                  iconColor: DevTrackColors.onTrack,
                  label: 'Assign To',
                  child: DropdownButtonFormField<String>(
                    initialValue: _assignee,
                    hint: const Text('Select team member'),
                    decoration: _inputDecoration(null),
                    borderRadius: BorderRadius.circular(14),
                    items: [
                      for (final member in _members)
                        DropdownMenuItem(
                          value: member.shortName,
                          child: Text('${member.name} · ${member.role}'),
                        ),
                      // keeping the old assignee when editing, even if they
                      // are not in the list (or the list is still loading)
                      if (_assignee != null &&
                          !_members.any((m) => m.shortName == _assignee))
                        DropdownMenuItem(
                          value: _assignee,
                          child: Text(_assignee!),
                        ),
                    ],
                    onChanged: (value) => setState(() => _assignee = value),
                    validator: (value) =>
                        value == null ? 'Please choose a team member' : null,
                  ),
                ),
                _IconField(
                  icon: Icons.calendar_today_outlined,
                  iconColor: DevTrackColors.ink,
                  label: 'Due Date',
                  child: FormField<DateTime>(
                    initialValue: _dueDate,
                    validator: _validateDueDate,
                    builder: (field) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _pickDueDate(field),
                        child: InputDecorator(
                          decoration: _inputDecoration(null).copyWith(
                            errorText: field.errorText,
                            suffixIcon: const Icon(
                              Icons.event_outlined,
                              color: DevTrackColors.muted,
                            ),
                          ),
                          child: Text(
                            _dueDate == null
                                ? 'Select date'
                                : _formatDueDate(_dueDate!),
                            style: TextStyle(
                              fontSize: 15,
                              color: _dueDate == null
                                  ? DevTrackColors.muted
                                  : DevTrackColors.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _IconField(
                  icon: Icons.flag_rounded,
                  iconColor: _priority.color,
                  label: 'Priority',
                  child: Row(
                    children: [
                      for (final priority in TaskPriority.values) ...[
                        if (priority != TaskPriority.values.first)
                          const SizedBox(width: 8),
                        Expanded(
                          child: _PriorityOption(
                            priority: priority,
                            selected: priority == _priority,
                            onTap: () => setState(() => _priority = priority),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _IconField(
                  icon: Icons.format_list_bulleted_rounded,
                  iconColor: DevTrackColors.ink,
                  label: 'Status',
                  child: DropdownButtonFormField<TaskStage>(
                    initialValue: _stage,
                    decoration: _inputDecoration(null),
                    borderRadius: BorderRadius.circular(14),
                    items: [
                      for (final stage in TaskStage.values)
                        DropdownMenuItem(
                          value: stage,
                          child: Text(stage.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _stage = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _isSaving
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            color: DevTrackColors.ink,
                          ),
                        ),
                      )
                    : DarkButton(
                        label: _isEditing ? 'Save Changes' : 'Create Task',
                        icon: _isEditing ? Icons.check : Icons.add,
                        onPressed: _saveTask,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// style for the input fields
InputDecoration _inputDecoration(String? hint) {
  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: DevTrackColors.muted),
    filled: true,
    fillColor: DevTrackColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: border(DevTrackColors.border),
    focusedBorder: border(DevTrackColors.ink, width: 1.5),
    errorBorder: border(DevTrackColors.overdue),
    focusedErrorBorder: border(DevTrackColors.overdue, width: 1.5),
  );
}

// formatting the due date
String _formatDueDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '${weekdays[date.weekday - 1]} ${date.day} '
      '${months[date.month - 1]}, $hour:$minute';
}

// label above a field
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: DevTrackColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// field with an icon on the left
class _IconField extends StatelessWidget {
  const _IconField({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 30),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DevTrackColors.tint(iconColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_FieldLabel(label), child],
            ),
          ),
        ],
      ),
    );
  }
}

// one priority button
class _PriorityOption extends StatelessWidget {
  const _PriorityOption({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final TaskPriority priority;
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? DevTrackColors.tint(priority.color)
                : DevTrackColors.surface,
            border: Border.all(
              color: selected ? priority.color : DevTrackColors.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            priority.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? priority.color : DevTrackColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
