import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/data_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _dataService = DataService();
  late Map<String, dynamic> _task;
  bool _isLoading = false;
  String? _photoProofUrl;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _photoProofUrl = _task['photo_proof_url'];
  }

  Future<void> _startTask() async {
    setState(() => _isLoading = true);
    final success = await _dataService.updateTaskStatus(
        _task['id'], 'In Progress');
    if (success) {
      setState(() {
        _task['status'] = 'In Progress';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsDone() async {
    setState(() => _isLoading = true);
    final success =
        await _dataService.updateTaskStatus(_task['id'], 'Done');
    if (success) {
      setState(() {
        _task['status'] = 'Done';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Task submitted for approval! ✅ Waiting for parent to approve.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() => _isLoading = true);

      final photoUrl = await _dataService.uploadPhotoProof(_task['id'], pickedFile);

      if (photoUrl != null) {
        setState(() {
          _photoProofUrl = photoUrl;
          _task['photo_proof_url'] = photoUrl;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully! 📸'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo. Please try again.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  void _showPhotoPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Photo Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _photoOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadPhoto(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _photoOptionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadPhoto(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _showTransferDialog() async {
  final members = await _dataService.getFamilyMembers();
  final otherMembers = members
      .where((m) => m['id'] != _task['assigned_to'])
      .toList();

  if (!mounted) return;

  String? selectedMemberId;
  String? selectedMemberName;
  final screenContext = context;

  showDialog(
    context: screenContext,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Transfer to Sibling'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select who to transfer this task to:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Select family member...'),
                  value: selectedMemberId,
                  items: otherMembers.map((m) {
                    return DropdownMenuItem<String>(
                      value: m['id'] as String,
                      child: Row(
                        children: [
                          Text(m['avatar'] ?? '👤',
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(m['name'] ?? ''),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    final member = otherMembers.firstWhere((m) => m['id'] == val);
                    setDialogState(() {
                      selectedMemberId = val;
                      selectedMemberName = member['name'];
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: selectedMemberId == null
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    setState(() => _isLoading = true);
                    final success = await _dataService.transferTask(
                        _task['id'], selectedMemberId!);
                    if (!mounted) return;
                    setState(() => _isLoading = false);
                    if (success) {
                      setState(() => _task['assigned_to'] = selectedMemberId);
                      ScaffoldMessenger.of(screenContext).showSnackBar(
                        SnackBar(
                          content: Text('Task transferred to $selectedMemberName ✅'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(screenContext).showSnackBar(
                        const SnackBar(
                          content: Text('Transfer failed. Try again.'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary),
            child: const Text('Transfer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

  void _showTimeExtensionDialog() {
    final reasonController = TextEditingController();
    final screenContext = context;
    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Request Time Extension'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tell your parent why you need more time:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. I have extra homework today...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(dialogContext);
              final success = await _dataService.requestTimeExtension(
                _task['id'],
                _task['title'] ?? '',
                reason,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(screenContext).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Time extension request sent! ✅'
                      : 'Failed to send request. Try again.'),
                  backgroundColor: success ? AppTheme.warning : AppTheme.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary),
            child: const Text('Send Request',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (_task['status']) {
      case 'Completed':
        return AppTheme.success;
      case 'In Progress':
        return AppTheme.warning;
      case 'Done':
        return AppTheme.secondary;
      default:
        return AppTheme.textLight;
    }
  }

  Color get _difficultyColor {
    switch (_task['difficulty']) {
      case 'Hard':
        return AppTheme.error;
      case 'Medium':
        return AppTheme.warning;
      default:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedUser = _task['assigned_user'];
    final avatar = assignedUser?['avatar'] ?? '👤';
    final name = assignedUser?['name'] ?? 'Unknown';
    final status = _task['status'] ?? 'Pending';
    final isInProgress = status == 'In Progress';
    final isPending = status == 'Pending';
    final isDone = status == 'Done' || status == 'Completed';
    final isAssignedToMe = _task['assigned_to'] == _dataService.currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding:
                    const EdgeInsets.fromLTRB(8, 20, 20, 28),
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
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(avatar,
                                style:
                                    const TextStyle(fontSize: 26)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                _task['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _badge(status, _statusColor),
                        const SizedBox(width: 8),
                        _badge(_task['difficulty'] ?? 'Medium',
                            _difficultyColor),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task details card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.primary.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Task Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_task['description'] != null &&
                              _task['description']
                                  .toString()
                                  .isNotEmpty) ...[
                            _detailRow(
                              label: 'Description',
                              value: _task['description'],
                            ),
                            const SizedBox(height: 10),
                          ],
                          _detailRowIcon(
                            icon: Icons.calendar_today_outlined,
                            value: _task['due_date'] != null
                                ? _formatDate(
                                    DateTime.parse(_task['due_date']))
                                : 'No due date',
                          ),
                          const SizedBox(height: 8),
                          _detailRowIcon(
                            icon: Icons.refresh,
                            value:
                                'Recurrence: ${_task['recurrence'] ?? 'None'}',
                          ),
                          const SizedBox(height: 8),
                          _detailRowIcon(
                            icon: Icons.emoji_events_outlined,
                            value: '${_task['points'] ?? 0} Points',
                            color: AppTheme.warning,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action buttons based on status
                    if (isPending && isAssignedToMe)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _startTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Start Task',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                    if (isInProgress && isAssignedToMe) ...[
                      // Complete task section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary
                                  .withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Complete Task',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Photo upload section
                            if (_photoProofUrl == null) ...[
                              GestureDetector(
                                onTap: _isLoading ? null : _showPhotoPickerOptions,
                                child: Container(
                                  width: double.infinity,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.primary.withOpacity(0.3),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        size: 36,
                                        color: AppTheme.primary.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Upload photo proof',
                                        style: TextStyle(
                                          color: AppTheme.primary.withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Show uploaded photo
                              Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(_photoProofUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Photo proof uploaded ✅',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Only show Mark as Done after photo is uploaded
                            if (_photoProofUrl != null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _markAsDone,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Mark as Done',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Transfer button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showTransferDialog,
                          icon: const Icon(Icons.send_outlined,
                              color: AppTheme.primary),
                          label: const Text(
                            'Transfer to Sibling',
                            style:
                                TextStyle(color: AppTheme.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            side: const BorderSide(
                                color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Time extension button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showTimeExtensionDialog,
                          icon: const Icon(Icons.access_time,
                              color: AppTheme.warning),
                          label: const Text(
                            'Request Time Extension',
                            style:
                                TextStyle(color: AppTheme.warning),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            side: const BorderSide(
                                color: AppTheme.warning),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (isDone) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.success, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppTheme.success, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status == 'Completed'
                                    ? 'Task completed and approved! 🎉'
                                    : 'Task submitted! Waiting for parent approval...',
                                style: const TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailRow({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textMedium)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _detailRowIcon({
    required IconData icon,
    required String value,
    Color color = AppTheme.textMedium,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(fontSize: 13, color: color),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}