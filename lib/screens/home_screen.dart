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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final members = await _dataService.getFamilyMembers();
    final tasks = await _dataService.getTodaysTasks();
    final user = await _dataService.getCurrentUser();
    final family = await _dataService.getCurrentFamily();
    setState(() {
      _familyMembers = members;
      _todaysTasks = tasks;
      _currentUser = user;
      _family = family;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoading ? SkeletonProfileHeader() : _buildHeader(),
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
                          children: List.generate(
                            3,
                            (index) => SkeletonTaskCard(),
                          ),
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

  Widget _buildHeader() {
    final familyName = _family?['name'] ?? 'Your Family';
    return Container(
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
                  'Complete all tasks for 25% bonus points! ⭐',
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.add_circle_outline,
                label: 'New Task',
                color: AppTheme.primary,
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
                color: AppTheme.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RewardsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.timeline_outlined,
                label: 'Feed',
                color: AppTheme.secondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FeedScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                color: AppTheme.secondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChatScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _actionButton(
          icon: Icons.notifications_outlined,
          label: 'Requests',
          color: AppTheme.accent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const RequestsScreen()),
          ),
          fullWidth: true,
        ),
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

  Widget _memberCard(Map<String, dynamic> member) {
    final todayDone = _todaysTasks
        .where((t) =>
            t['assigned_to'] == member['id'] && t['status'] == 'Completed')
        .length;
    final todayTotal = _todaysTasks
        .where((t) => t['assigned_to'] == member['id'])
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.08),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
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
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
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
    );
  }

  Widget _buildTodaysTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Tasks",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_todaysTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'No tasks for today! 🎉',
                style: TextStyle(color: AppTheme.textMedium),
              ),
            ),
          )
        else
          ..._todaysTasks.map((task) => _taskCard(task)).toList(),
      ],
    );
  }

 Widget _taskCard(Map<String, dynamic> task) {
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
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.06),
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
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(avatar, style: const TextStyle(fontSize: 22)),
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
                      _chip('${task['points']} pts', AppTheme.primary),
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