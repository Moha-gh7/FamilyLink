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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tasks = await _dataService.getPendingApprovals();
    setState(() {
      _doneTasks = tasks;
      _isLoading = false;
    });
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
                      '${_doneTasks.length} pending requests',
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
                    tabs: const [
                      Tab(text: 'Tasks'),
                      Tab(text: 'Done'),
                      Tab(text: 'Rewards'),
                      Tab(text: 'Transfers'),
                      Tab(text: 'Time'),
                    ],
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _emptyTab('No pending task requests'),
                        _doneTab(),
                        _emptyTab('No reward requests pending'),
                        _emptyTab('No transfer requests pending'),
                        _emptyTab('No time extension requests'),
                      ],
                    ),
            ),
          ],
        ),
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

  Widget _doneTab() {
    if (_doneTasks.isEmpty) {
      return _emptyTab('No completed tasks pending approval');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
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
            tagColor: AppTheme.primary,
            extraWidget: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_camera_outlined,
                      size: 14, color: AppTheme.primary),
                  SizedBox(width: 4),
                  Text('Waiting for photo proof',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.primary)),
                ],
              ),
            ),
            onApprove: () async {
              final assignedTo = task['assigned_to'];
              final points = task['points'] as int;
              final success = await _dataService.approveTask(
                  task['id'], points, assignedTo);
              if (success) {
                _loadData();
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
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task rejected — sent back to Pending'),
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
    required VoidCallback onApprove,
    required VoidCallback onReject,
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
            color: AppTheme.primary.withOpacity(0.06),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
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
                  onPressed: onApprove,
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