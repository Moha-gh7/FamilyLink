import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/data_service.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedMember = 'Select family member...';
  String _difficulty = 'Medium';
  String _recurrence = 'None';
  int _points = 20;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isLoading = false;

 final _dataService = DataService();
List<String> _members = ['Select family member...'];
Map<String, String> _memberIdMap = {};

@override
void initState() {
  super.initState();
  _loadMembers();
}

Future<void> _loadMembers() async {
  final members = await _dataService.getFamilyMembers();
  final idMap = <String, String>{};
  for (final m in members) {
    idMap['${m['avatar']} ${m['name']}'] = m['id'] as String;
  }
  setState(() {
    _members = ['Select family member...',
      ...members.map((m) => '${m['avatar']} ${m['name']}').toList()
    ];
    _memberIdMap = idMap;
  });
}

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> _recurrences = ['None', 'Daily', 'Weekly'];

  final List<String> _templates = [
    'Clean your bedroom',
    'Wash the dishes',
    'Take out the trash',
    'Do the laundry',
    'Vacuum the house',
    'Mop the floors',
    'Water the plants',
    'Walk the dog',
    'Prepare iftar',
    'Fold the clothes',
    'Clean the bathroom',
    'Buy groceries',
    'Feed the cat',
    'Help with homework',
    'Tidy the living room',
    'Wipe kitchen counters',
    'Set the table',
    'Take out recycling',
  ];

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _dueDate = date);
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) setState(() => _dueTime = time);
    }
  }

  String get _formattedDateTime {
    if (_dueDate == null) return 'Select date & time';
    final date =
        '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}';
    final time = _dueTime != null
        ? ' ${_dueTime!.hour}:${_dueTime!.minute.toString().padLeft(2, '0')}'
        : '';
    return '$date$time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create New Task',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Assign tasks to family members',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Templates
                    const Text(
                      'Quick Templates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _templates.map((template) {
                        return GestureDetector(
                          onTap: () => setState(
                              () => _titleController.text = template),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _titleController.text == template
                                    ? AppTheme.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              template,
                              style: TextStyle(
                                fontSize: 12,
                                color: _titleController.text == template
                                    ? AppTheme.primary
                                    : AppTheme.textMedium,
                                fontWeight: _titleController.text == template
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Task title
                    _buildLabel('Task Title *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: _inputDecoration(
                          'e.g. Clean your bedroom'),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    _buildLabel('Description'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                          'Add details about what needs to be done...'),
                    ),

                    const SizedBox(height: 16),

                    // Assign to
                    _buildLabel('Assign To *'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMember,
                          isExpanded: true,
                          items: _members.map((m) {
                            return DropdownMenuItem(
                                value: m, child: Text(m));
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedMember = val!),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Due date
                    _buildLabel('Due Date & Time *'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: AppTheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _formattedDateTime,
                              style: TextStyle(
                                color: _dueDate == null
                                    ? Colors.grey
                                    : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Difficulty
                    _buildLabel('Difficulty'),
                    const SizedBox(height: 8),
                    Row(
                      children: _difficulties.map((d) {
                        final isSelected = _difficulty == d;
                        Color color;
                        switch (d) {
                          case 'Hard':
                            color = AppTheme.error;
                            break;
                          case 'Medium':
                            color = AppTheme.warning;
                            break;
                          default:
                            color = AppTheme.success;
                        }
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _difficulty = d),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withOpacity(0.15)
                                    : AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : AppTheme.textMedium,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Recurrence
                    _buildLabel('Recurrence'),
                    const SizedBox(height: 8),
                    Row(
                      children: _recurrences.map((r) {
                        final isSelected = _recurrence == r;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _recurrence = r),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withOpacity(0.12)
                                    : AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                r,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textMedium,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Points
                    _buildLabel('Point Value'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_points > 5) {
                              setState(() => _points -= 5);
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppTheme.primary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: AppTheme.warning, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '$_points pts',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _points += 5),
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppTheme.primary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                           if (_titleController.text.isEmpty ||
                            _selectedMember == 'Select family member...' ||
                               _dueDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Please fill in all required fields')),
                                 );
                                                     return;
                                                            }
                                                           if (mounted) setState(() => _isLoading = true);
                                               final dueDateTime = DateTime(
                                                 _dueDate!.year,
                                                                          _dueDate!.month,
                                                          _dueDate!.day,
                                                                  _dueTime?.hour ?? 23,
                                                                _dueTime?.minute ?? 59,
                                                                         );
                                                       final assignedToId = _memberIdMap[_selectedMember] ?? _selectedMember;
                                                       final success = await _dataService.createTask(
                                                         title: _titleController.text.trim(),
                                                        description: _descriptionController.text.trim(),
                                                            assignedTo: assignedToId,
                                                              dueDate: dueDateTime,
                                                        difficulty: _difficulty,
                                                recurrence: _recurrence,
                                                                          points: _points,
                                                      );
                                                              if (!mounted) return;
                                                              setState(() => _isLoading = false);
                                                      if (success) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(
                                                       content: Text('Task created successfully! ✅'),
                                                 backgroundColor: AppTheme.success,
                                                       ),
                                                       );
                                                                     Navigator.pop(context);
                                                      } else {
                                                   ScaffoldMessenger.of(context).showSnackBar(
                                                 const SnackBar(
                                         content: Text('Failed to create task. Try again.'),
                                                 backgroundColor: AppTheme.error,   ),
    );
  }
},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Create Task',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }
}