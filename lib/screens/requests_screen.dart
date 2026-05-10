import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/data_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dataService = DataService();

  List<Map<String, dynamic>> _doneTasks = [];
  List<Map<String, dynamic>> _transferRequests = [];
  List<Map<String, dynamic>> _pendingApprovalTasks = [];
  List<Map<String, dynamic>> _timeExtensionTasks = [];
  List<Map<String, dynamic>> _redemptionRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _dataService.getPendingApprovals(),
      _dataService.getPendingTaskApprovals(),
      _dataService.getTimeExtensionRequests(),
      _dataService.getRedemptionRequests(),
      _dataService.getTransferRequests(),
    ]);
    setState(() {
      _doneTasks = results[0] as List<Map<String, dynamic>>;
      _pendingApprovalTasks = results[1] as List<Map<String, dynamic>>;
      _timeExtensionTasks = results[2] as List<Map<String, dynamic>>;
      _redemptionRequests = results[3] as List<Map<String, dynamic>>;
      _transferRequests = results[4] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  }

  void _showPhotoDialog(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Task Proof',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Failed to load image'),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'Requests',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 16),
                    child: Text(
                      '${_pendingApprovalTasks.length + _doneTasks.length + _redemptionRequests.length + _transferRequests.length + _timeExtensionTasks.length} pending requests',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    tabs: [
                      _tabWithBadge('Tasks', _pendingApprovalTasks.isNotEmpty),
                      _tabWithBadge('Done', _doneTasks.isNotEmpty),
                      _tabWithBadge('Rewards', _redemptionRequests.isNotEmpty),
                      _tabWithBadge('Transfers', _transferRequests.isNotEmpty),
                      _tabWithBadge('Time', _timeExtensionTasks.isNotEmpty),
                    ],
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _pendingTasksTab(),
                        _doneTab(),
                        _redemptionsTab(),
                        _transfersTab(),
                        _timeExtensionTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabWithBadge(String label, bool hasBadge) {
    return Tab(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(right: hasBadge ? 10 : 0),
            child: Text(label),
          ),
          if (hasBadge)
            Positioned(
              top: -2,
              right: -4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 60, color: AppTheme.textLight),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingTasksTab() {
    if (_pendingApprovalTasks.isEmpty) {
      return _emptyTab('No task requests from children');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingApprovalTasks.length,
        itemBuilder: (context, index) {
          final task = _pendingApprovalTasks[index];
          final creator = task['creator'];
          final assigned = task['assigned_user'];
          final creatorName = creator?['name'] ?? 'Unknown';
          final assignedName = assigned?['name'] ?? 'Unknown';
          final avatar = creator?['avatar'] ?? '👤';

          return _requestCard(
            emoji: avatar,
            title: task['title'] ?? '',
            subtitle: 'By $creatorName → $assignedName • ${task['points']} pts',
            tag: 'New Task',
            tagColor: AppTheme.warning,
            approveLabel: 'Approve',
            onApprove: () async {
              final success = await _dataService.approveTaskCreation(task['id']);
              if (success) {
                if (!mounted) return;
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task approved and added ✅'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              }
            },
            onReject: () async {
              await _dataService.rejectTaskCreation(task['id']);
              if (!mounted) return;
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task request rejected'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _doneTab() {
    if (_doneTasks.isEmpty) {
      return _emptyTab('No completed tasks pending approval');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _doneTasks.length,
        itemBuilder: (context, index) {
          final task = _doneTasks[index];
          final assignedUser = task['assigned_user'];
          final avatar = assignedUser?['avatar'] ?? '👤';
          final name = assignedUser?['name'] ?? 'Unknown';

          return _requestCard(
            emoji: avatar,
            title: task['title'] ?? '',
            subtitle: '$name • ${task['points']} pts',
            tag: '${task['points']} pts',
            tagColor: Theme.of(context).colorScheme.primary,
            extraWidget: task['photo_proof_url'] != null
                ? Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 14, color: AppTheme.success),
                        SizedBox(width: 4),
                        Text('Photo proof available',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.success)),
                      ],
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined,
                            size: 14, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 4),
                        Text('Waiting for photo proof',
                            style: TextStyle(
                                fontSize: 11, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
            onApprove: () async {
              final assignedTo = task['assigned_to'];
              final points = task['points'] as int;
              final success = await _dataService.approveTask(
                  task['id'], points, assignedTo);
              if (success) {
                if (!mounted) return;
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task approved! Points added ✅'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              }
            },
            onReject: () async {
              await _dataService.updateTaskStatus(
                  task['id'], 'Pending');
              if (!mounted) return;
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task rejected — sent back to Pending'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            onViewPhoto: task['photo_proof_url'] != null
                ? () => _showPhotoDialog(task['photo_proof_url'])
                : null,
          );
        },
      ),
    );
  }

  Widget _redemptionsTab() {
    if (_redemptionRequests.isEmpty) {
      return _emptyTab('No reward redemption requests');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _redemptionRequests.length,
        itemBuilder: (context, index) {
          final r = _redemptionRequests[index];
          final reward = r['reward'];
          final redeemer = r['redeemer'];
          final emoji = reward?['emoji'] ?? '🎁';
          final title = reward?['title'] ?? 'Unknown Reward';
          final pointsCost = (reward?['points_cost'] ?? 0) as int;
          final name = redeemer?['name'] ?? 'Unknown';
          final avatar = redeemer?['avatar'] ?? '👤';

          return _requestCard(
            emoji: avatar,
            title: '$emoji $title',
            subtitle: '$name wants to redeem • $pointsCost pts',
            tag: 'Reward',
            tagColor: Theme.of(context).colorScheme.primary,
            approveLabel: 'Fulfill ✅',
            onApprove: () async {
              final success = await _dataService.approveRedemption(r['id']);
              if (success) {
                if (!mounted) return;
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reward fulfilled for $name! 🎁'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              }
            },
            onReject: () async {
              await _dataService.rejectRedemption(
                  r['id'], r['user_id'], pointsCost);
              if (!mounted) return;
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Redemption rejected — ${pointsCost} pts refunded to $name'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _transfersTab() {
    if (_transferRequests.isEmpty) {
      return _emptyTab('No transfer requests pending');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transferRequests.length,
        itemBuilder: (context, index) {
          final task = _transferRequests[index];
          final from = task['assigned_user'];
          final to = task['transfer_to'];
          final fromName = from?['name'] ?? 'Unknown';
          final fromAvatar = from?['avatar'] ?? '👤';
          final toName = to?['name'] ?? 'Unknown';
          final toAvatar = to?['avatar'] ?? '👤';

          return _requestCard(
            emoji: fromAvatar,
            title: task['title'] ?? '',
            subtitle: '$fromName → $toAvatar $toName',
            tag: 'Transfer',
            tagColor: Colors.blue,
            approveLabel: 'Approve ✅',
            onApprove: () async {
              final success = await _dataService.approveTransfer(
                task['id'],
                task['transfer_requested_to'],
              );
              if (success) {
                if (!mounted) return;
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Task transferred to $toName ✅'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              }
            },
            onReject: () async {
              await _dataService.rejectTransfer(task['id']);
              if (!mounted) return;
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transfer rejected — task stays with $fromName'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _timeExtensionTab() {
    if (_timeExtensionTasks.isEmpty) {
      return _emptyTab('No time extension requests');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _timeExtensionTasks.length,
        itemBuilder: (context, index) {
          final task = _timeExtensionTasks[index];
          final assigned = task['assigned_user'];
          final avatar = assigned?['avatar'] ?? '👤';
          final name = assigned?['name'] ?? 'Unknown';
          final reason = task['extension_reason'] ?? 'No reason given';
          final dueDate = task['due_date'] != null
              ? DateTime.parse(task['due_date'])
              : DateTime.now();

          return _requestCard(
            emoji: avatar,
            title: task['title'] ?? '',
            subtitle: '$name • Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
            tag: 'Extension',
            tagColor: AppTheme.warning,
            approveLabel: '+2 Days',
            extraWidget: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 14, color: AppTheme.warning),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      reason,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),
            onApprove: () async {
              final success = await _dataService.approveTimeExtension(task['id'], dueDate);
              if (success) {
                if (!mounted) return;
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Extended due date for "${task['title']}" by 2 days ✅'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              }
            },
            onReject: () async {
              await _dataService.rejectTimeExtension(task['id']);
              if (!mounted) return;
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Time extension rejected'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _requestCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required Future<void> Function() onApprove,
    required Future<void> Function() onReject,
    VoidCallback? onViewPhoto,
    String approveLabel = 'Approve',
    Widget? extraWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
          if (extraWidget != null) extraWidget,
          const SizedBox(height: 12),
          if (onViewPhoto != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewPhoto,
                icon: Icon(Icons.photo_camera, color: Theme.of(context).colorScheme.primary),
                label: Text(
                  'View Photo Proof',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async => await onReject(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async => await onApprove(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    approveLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}