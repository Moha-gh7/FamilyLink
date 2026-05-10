import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/data_service.dart';
import '../widgets/skeleton_loader.dart';
import 'new_task_screen.dart';
import 'feed_screen.dart';
import 'chat_screen.dart';
import 'rewards_screen.dart';
import 'requests_screen.dart';
import 'settings_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dataService = DataService();

  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _todaysTasks = [];
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _family;
  bool _isLoading = true;

  // Badge state
  int _requestsBadge = 0;
  bool _chatBadge = false;
  bool _feedBadge = false;

  // Persists within the session — tracks when user last opened each screen
  static DateTime? _lastChatOpen;
  static DateTime? _lastFeedOpen;

  @override
  void initState() {
    super.initState();
    // Mark everything as seen at session start — only NEW activity triggers badges
    _lastChatOpen ??= DateTime.now();
    _lastFeedOpen ??= DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _dataService.getFamilyMembers(),
      _dataService.getTodaysTasks(),
      _dataService.getCurrentUser(),
      _dataService.getCurrentFamily(),
      _dataService.getPendingRequestsCount(),
      _dataService.getLatestMessageTime(),
      _dataService.getLatestFeedTime(),
    ]);

    final members = results[0] as List<Map<String, dynamic>>;
    final tasks = results[1] as List<Map<String, dynamic>>;
    final user = results[2] as Map<String, dynamic>?;
    final family = results[3] as Map<String, dynamic>?;
    final requestCount = results[4] as int;
    final latestMsg = results[5] as DateTime?;
    final latestFeed = results[6] as DateTime?;

    setState(() {
      _familyMembers = members;
      _todaysTasks = tasks;
      _currentUser = user;
      _family = family;
      _requestsBadge = requestCount;
      _chatBadge = latestMsg != null &&
          (_lastChatOpen == null || latestMsg.isAfter(_lastChatOpen!));
      _feedBadge = latestFeed != null &&
          (_lastFeedOpen == null || latestFeed.isAfter(_lastFeedOpen!));
      _isLoading = false;
    });
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String get todayDate {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  int get completedTasks =>
      _todaysTasks.where((t) => t['status'] == 'Completed').length;

  bool get _canApprove =>
      _currentUser?['role'] == 'Parent' ||
      _currentUser?['can_approve'] == true;

  bool get _isChild => _currentUser?['role'] != 'Parent';

  int get _overdueCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _todaysTasks.where((t) {
      if (t['status'] == 'Completed' || t['status'] == 'Done') return false;
      if (t['assigned_to'] != _dataService.currentUserId) return false;
      if (t['due_date'] == null) return false;
      final due = DateTime.parse(t['due_date']);
      final dueDay = DateTime(due.year, due.month, due.day);
      return dueDay.isBefore(today);
    }).length;
  }

  Color _taskUrgencyColor(Map<String, dynamic> task) {
    if (task['status'] == 'Completed' || task['status'] == 'Done') {
      return AppTheme.success;
    }
    if (task['due_date'] == null) return AppTheme.textLight;
    final due = DateTime.parse(task['due_date']);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    if (dueDay.isBefore(today)) return AppTheme.error;
    if (dueDay == today) return AppTheme.warning;
    return AppTheme.success;
  }

  String _taskEmoji(String title) {
    final t = title.toLowerCase();
    if (t.contains('clean')) return '🧹';
    if (t.contains('dish') || t.contains('wash')) return '🫧';
    if (t.contains('trash') || t.contains('recycl')) return '🗑️';
    if (t.contains('laundry') || t.contains('cloth') || t.contains('fold')) return '👕';
    if (t.contains('vacuum')) return '🌀';
    if (t.contains('plant') || t.contains('water')) return '🌿';
    if (t.contains('dog')) return '🐕';
    if (t.contains('cat')) return '🐈';
    if (t.contains('homework') || t.contains('study')) return '📚';
    if (t.contains('cook') || t.contains('dinner') || t.contains('food') || t.contains('iftar') || t.contains('prepare')) return '🥘';
    if (t.contains('bed') || t.contains('room')) return '🛏️';
    if (t.contains('grocery') || t.contains('buy')) return '🛒';
    if (t.contains('table') || t.contains('set')) return '🍴';
    if (t.contains('mop') || t.contains('floor')) return '🧽';
    if (t.contains('feed')) return '🥣';
    return '📋';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: Theme.of(context).colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoading ? SkeletonProfileHeader() : _buildHeader(),
                if (!_isLoading && _overdueCount > 0) _buildOverdueBanner(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isLoading
                      ? SkeletonLoader(
                          isLoading: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              3,
                              (index) => SkeletonBox(
                                width: 100,
                                height: 80,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      : _buildActionButtons(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoading
                      ? SkeletonFamilyMembersList()
                      : _buildFamilyMembers(),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isLoading
                      ? Column(
                          children: List.generate(3, (index) => SkeletonTaskCard()),
                        )
                      : _buildTodaysTasks(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverdueBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            '⚠️ You have $_overdueCount overdue task${_overdueCount > 1 ? 's' : ''}!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final familyName = _family?['name'] ?? 'Your Family';
    return Container(
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$greeting, $familyName! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 24),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            todayDate,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Family Progress Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$completedTasks/${_todaysTasks.length} tasks',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _todaysTasks.isEmpty
                        ? 0
                        : completedTasks / _todaysTasks.length,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep going — every task earns points! 💪',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge({int? count, bool dot = false}) {
    final showCount = count != null && count > 0;
    if (!showCount && !dot) return const SizedBox.shrink();
    return Container(
      padding: showCount
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: showCount
          ? Text(
              count! > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            )
          : null,
    );
  }

  Widget _withBadge(Widget child, {int? count, bool dot = false}) {
    final showCount = count != null && count > 0;
    if (!showCount && !dot) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -6,
          right: -6,
          child: _badge(count: count, dot: dot),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.add_circle_outline,
                label: 'New Task',
                color: Theme.of(context).colorScheme.primary,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewTaskScreen()),
                  );
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                icon: Icons.card_giftcard_outlined,
                label: 'Rewards',
                color: Theme.of(context).colorScheme.primary,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RewardsScreen()),
                  );
                  _loadData();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _withBadge(
                _actionButton(
                  icon: Icons.timeline_outlined,
                  label: 'Feed',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () async {
                    setState(() {
                      _lastFeedOpen = DateTime.now();
                      _feedBadge = false;
                    });
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FeedScreen()),
                    );
                    _loadData();
                  },
                ),
                dot: _feedBadge,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _withBadge(
                _actionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () async {
                    setState(() {
                      _lastChatOpen = DateTime.now();
                      _chatBadge = false;
                    });
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChatScreen()),
                    );
                    _loadData();
                  },
                ),
                dot: _chatBadge,
              ),
            ),
          ],
        ),
        if (_canApprove) ...[
          const SizedBox(height: 12),
          _withBadge(
            _actionButton(
              icon: Icons.notifications_outlined,
              label: 'Requests',
              color: AppTheme.accent,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RequestsScreen()),
                );
                _loadData();
              },
              fullWidth: true,
            ),
            count: _requestsBadge,
          ),
        ],
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMembers() {
    if (_familyMembers.isEmpty) {
      return const Center(
        child: Text('No family members yet',
            style: TextStyle(color: AppTheme.textMedium)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Family Members',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: _familyMembers.length,
          itemBuilder: (context, index) {
            return _memberCard(_familyMembers[index]);
          },
        ),
      ],
    );
  }

  void _showMemberTasks(Map<String, dynamic> member) {
    final memberTasks = _todaysTasks
        .where((t) => t['assigned_to'] == member['id'])
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Member header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),

                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Center(
                      child: Text(member['avatar'] ?? '👤',
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          member['role'] ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.white, size: 20),
                      Text(
                        '${member['points'] ?? 0} pts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tasks label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Assigned Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${memberTasks.length} task${memberTasks.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Tasks list
            Flexible(
              child: memberTasks.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Text('🎉', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 8),
                          Text('No tasks assigned',
                              style: TextStyle(
                                  color: AppTheme.textMedium,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: memberTasks.length,
                      itemBuilder: (context, index) {
                        final task = memberTasks[index];
                        final urgencyColor = _taskUrgencyColor(task);
                        final status = task['status'] ?? 'Pending';

                        Color statusColor;
                        switch (status) {
                          case 'Completed':
                            statusColor = AppTheme.success;
                            break;
                          case 'In Progress':
                            statusColor = AppTheme.warning;
                            break;
                          case 'Done':
                            statusColor = Theme.of(context).colorScheme.secondary;
                            break;
                          default:
                            statusColor = AppTheme.textLight;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border(
                              left: BorderSide(
                                  color: urgencyColor, width: 4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      urgencyColor.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    _taskEmoji(task['title'] ?? ''),
                                    style: const TextStyle(
                                        fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.emoji_events,
                                            size: 12,
                                            color: AppTheme.warning),
                                        const SizedBox(width: 3),
                                        Text('${task['points']} pts',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppTheme.textMedium)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      statusColor.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> member) {
    final todayDone = _todaysTasks
        .where((t) =>
            t['assigned_to'] == member['id'] && t['status'] == 'Completed')
        .length;
    final todayTotal = _todaysTasks
        .where((t) => t['assigned_to'] == member['id'])
        .length;

    return GestureDetector(
      onTap: () => _showMemberTasks(member),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 8,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(member['avatar'] ?? '👤',
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    member['role'] ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Points',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textMedium)),
              Text(
                '${member['points'] ?? 0}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: todayTotal == 0 ? 0 : todayDone / todayTotal,
              backgroundColor: AppTheme.cardBg,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Today $todayDone/$todayTotal',
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textMedium),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTodaysTasks() {
    final myTasks = _todaysTasks
        .where((t) => t['assigned_to'] == _dataService.currentUserId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Tasks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (myTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Column(
                children: [
                  Text('🎉', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text('No tasks assigned to you today!',
                      style: TextStyle(
                          color: AppTheme.textMedium,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )
        else
          ...myTasks.map((task) => _childTaskCard(task)).toList(),
      ],
    );
  }

  Widget _childTaskCard(Map<String, dynamic> task) {
    final urgencyColor = _taskUrgencyColor(task);
    final status = task['status'] ?? 'Pending';
    final isPending = status == 'Pending';
    final isInProgress = status == 'In Progress';
    final isDone = status == 'Completed' || status == 'Done';

    String dueDateText = '';
    if (task['due_date'] != null) {
      final due = DateTime.parse(task['due_date']);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(due.year, due.month, due.day);
      if (dueDay.isBefore(today)) {
        dueDateText = 'Overdue!';
      } else if (dueDay == today) {
        dueDateText = 'Due today';
      } else {
        dueDateText = 'Due ${due.day}/${due.month}';
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: urgencyColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _taskEmoji(task['title'] ?? ''),
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: urgencyColor),
                      const SizedBox(width: 4),
                      Text(
                        dueDateText,
                        style: TextStyle(
                          fontSize: 12,
                          color: urgencyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.emoji_events,
                          size: 12, color: AppTheme.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${task['points']} pts',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMedium),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isDone)
              const Icon(Icons.check_circle,
                  color: AppTheme.success, size: 28)
            else if (isPending || isInProgress)
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(task: task)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: urgencyColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isPending ? 'Start' : 'Go!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    final urgencyColor = _taskUrgencyColor(task);

    Color statusColor;
    switch (task['status']) {
      case 'Completed':
        statusColor = AppTheme.success;
        break;
      case 'In Progress':
        statusColor = AppTheme.warning;
        break;
      default:
        statusColor = AppTheme.textLight;
    }

    Color difficultyColor;
    switch (task['difficulty']) {
      case 'Hard':
        difficultyColor = AppTheme.error;
        break;
      case 'Medium':
        difficultyColor = AppTheme.warning;
        break;
      default:
        difficultyColor = AppTheme.success;
    }

    final assignedUser = task['assigned_user'];
    final avatar = assignedUser?['avatar'] ?? '👤';
    final name = assignedUser?['name'] ?? 'Unknown';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailScreen(task: task),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: urgencyColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _taskEmoji(task['title'] ?? ''),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(avatar,
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip('${task['points']} pts', Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      _chip(task['difficulty'] ?? '', difficultyColor),
                      const SizedBox(width: 6),
                      _chip(task['status'] ?? '', statusColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
