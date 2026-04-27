import 'package:flutter/material.dart';
import '../theme.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> doneTasks = [
    {
      'emoji': '👦',
      'name': 'Yusuf',
      'task': 'Clean your bedroom',
      'points': 30,
      'time': '2 hours ago',
      'hasPhoto': true,
    },
    {
      'emoji': '👧',
      'name': 'Aisha',
      'task': 'Wash the dishes',
      'points': 20,
      'time': '5 hours ago',
      'hasPhoto': true,
    },
  ];

  final List<Map<String, dynamic>> transfers = [
    {
      'emoji': '👦',
      'name': 'Yusuf',
      'task': 'Take out the trash',
      'transferTo': 'Aisha',
      'time': '1 hour ago',
    },
  ];

  final List<Map<String, dynamic>> timeRequests = [
    {
      'emoji': '👧',
      'name': 'Aisha',
      'task': 'Do the laundry',
      'reason': 'I have extra homework today',
      'time': '3 hours ago',
    },
  ];

  final List<Map<String, dynamic>> rewardRequests = [
    {
      'emoji': '👦',
      'name': 'Yusuf',
      'reward': 'Movie Night',
      'points': 200,
      'time': '1 day ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                      '${doneTasks.length + transfers.length + timeRequests.length + rewardRequests.length} pending requests',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  // Tabs
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
              child: TabBarView(
                controller: _tabController,
                children: [
                  _emptyTab('No pending task requests'),
                  _doneTab(),
                  _rewardsTab(),
                  _transfersTab(),
                  _timeTab(),
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
          Icon(Icons.inbox_outlined, size: 60, color: AppTheme.textLight),
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
    if (doneTasks.isEmpty) return _emptyTab('No completed tasks pending');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: doneTasks.length,
      itemBuilder: (context, index) {
        final task = doneTasks[index];
        return _requestCard(
          emoji: task['emoji'],
          title: task['task'],
          subtitle: '${task['name']} • ${task['time']}',
          tag: '${task['points']} pts',
          tagColor: AppTheme.primary,
          extraWidget: task['hasPhoto']
              ? Container(
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
                      Text('Photo proof uploaded',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.primary)),
                    ],
                  ),
                )
              : null,
          onApprove: () => setState(() => doneTasks.removeAt(index)),
          onReject: () => setState(() => doneTasks.removeAt(index)),
        );
      },
    );
  }

  Widget _rewardsTab() {
    if (rewardRequests.isEmpty) {
      return _emptyTab('No reward requests pending');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewardRequests.length,
      itemBuilder: (context, index) {
        final reward = rewardRequests[index];
        return _requestCard(
          emoji: reward['emoji'],
          title: '${reward['name']} wants: ${reward['reward']}',
          subtitle: reward['time'],
          tag: '${reward['points']} pts',
          tagColor: AppTheme.warning,
          onApprove: () =>
              setState(() => rewardRequests.removeAt(index)),
          onReject: () =>
              setState(() => rewardRequests.removeAt(index)),
          approveLabel: 'Fulfilled',
        );
      },
    );
  }

  Widget _transfersTab() {
    if (transfers.isEmpty) {
      return _emptyTab('No transfer requests pending');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        final transfer = transfers[index];
        return _requestCard(
          emoji: transfer['emoji'],
          title: transfer['task'],
          subtitle:
              '${transfer['name']} → ${transfer['transferTo']} • ${transfer['time']}',
          tag: 'Transfer',
          tagColor: AppTheme.secondary,
          onApprove: () => setState(() => transfers.removeAt(index)),
          onReject: () => setState(() => transfers.removeAt(index)),
        );
      },
    );
  }

  Widget _timeTab() {
    if (timeRequests.isEmpty) {
      return _emptyTab('No time extension requests');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: timeRequests.length,
      itemBuilder: (context, index) {
        final req = timeRequests[index];
        return _requestCard(
          emoji: req['emoji'],
          title: req['task'],
          subtitle: '${req['name']} • ${req['time']}',
          tag: 'Extension',
          tagColor: AppTheme.warning,
          extraWidget: Container(
            margin: const EdgeInsets.only(top: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '"${req['reason']}"',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          onApprove: () => setState(() => timeRequests.removeAt(index)),
          onReject: () => setState(() => timeRequests.removeAt(index)),
        );
      },
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
                  child:
                      Text(emoji, style: const TextStyle(fontSize: 22)),
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
