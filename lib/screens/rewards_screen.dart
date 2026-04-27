import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/data_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _dataService = DataService();
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _rewards = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;

  // Default rewards to add if none exist
  final List<Map<String, dynamic>> _defaultRewards = [
    {
      'emoji': '🍦',
      'title': 'Ice Cream Trip',
      'description': 'Family outing to favorite ice cream parlor',
      'points_cost': 150,
    },
    {
      'emoji': '🎬',
      'title': 'Movie Night',
      'description': 'Choose any movie + popcorn',
      'points_cost': 200,
    },
    {
      'emoji': '🎮',
      'title': 'Extra Screen Time',
      'description': '1 hour extra phone/game time',
      'points_cost': 100,
    },
    {
      'emoji': '🍕',
      'title': 'Pizza Night',
      'description': 'Pick your favorite pizza toppings',
      'points_cost': 175,
    },
    {
      'emoji': '🎁',
      'title': 'Mystery Gift',
      'description': 'A surprise gift from parents',
      'points_cost': 500,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final members = await _dataService.getFamilyMembers();
    var rewards = await _dataService.getRewards();
    final user = await _dataService.getCurrentUser();

    // If no rewards exist, add default ones
    if (rewards.isEmpty && user != null) {
      await _addDefaultRewards(user['family_id']);
      rewards = await _dataService.getRewards();
    }

    // Sort members by points
    members.sort((a, b) =>
        (b['points'] as int).compareTo(a['points'] as int));

    setState(() {
      _members = members;
      _rewards = rewards;
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _addDefaultRewards(String familyId) async {
    for (final reward in _defaultRewards) {
      await _dataService.supabase.from('rewards').insert({
        'family_id': familyId,
        'title': reward['title'],
        'description': reward['description'],
        'emoji': reward['emoji'],
        'points_cost': reward['points_cost'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final userPoints = _currentUser?['points'] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8593C), Color(0xFFF4A261)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 20, 20, 28),
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
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Center(
                            child: Text(
                              _currentUser?['avatar'] ?? '👤',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Points',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.white70),
                            ),
                            Row(
                              children: [
                                Text(
                                  '$userPoints',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.emoji_events,
                                    color: Colors.white, size: 28),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a reward to unlock with your points!',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leaderboard
                    const Text(
                      '✨ Family Leaderboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _members.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No members yet',
                                  style: TextStyle(
                                      color: AppTheme.textMedium)),
                            )
                          : Column(
                              children: _members
                                  .asMap()
                                  .entries
                                  .map((entry) => _leaderboardRow(
                                      entry.value,
                                      entry.key + 1,
                                      entry.key ==
                                          _members.length - 1))
                                  .toList(),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Available rewards
                    const Text(
                      'Available Rewards',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._rewards
                        .map((r) => _rewardCard(r, userPoints, context))
                        .toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leaderboardRow(
      Map<String, dynamic> member, int rank, bool isLast) {
    String rankEmoji;
    Color pointsColor;

    switch (rank) {
      case 1:
        rankEmoji = '🥇';
        pointsColor = Colors.pink;
        break;
      case 2:
        rankEmoji = '🥈';
        pointsColor = AppTheme.primary;
        break;
      case 3:
        rankEmoji = '🥉';
        pointsColor = AppTheme.warning;
        break;
      default:
        rankEmoji = '$rank';
        pointsColor = AppTheme.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom:
                    BorderSide(color: AppTheme.cardBg, width: 1)),
      ),
      child: Row(
        children: [
          Text(rankEmoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member['name'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Text(
            '${member['points'] ?? 0} pts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: pointsColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardCard(
      Map<String, dynamic> reward, int userPoints, BuildContext context) {
    final pointsCost = reward['points_cost'] as int;
    final canAfford = userPoints >= pointsCost;
    final progress = (userPoints / pointsCost).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(reward['emoji'] ?? '🎁',
                  style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reward['description'] ?? '',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      canAfford
                          ? 'You can unlock this!'
                          : '${pointsCost - userPoints} pts needed',
                      style: TextStyle(
                        fontSize: 11,
                        color: canAfford
                            ? AppTheme.success
                            : AppTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text('$pointsCost ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        )),
                    const Icon(Icons.emoji_events,
                        color: AppTheme.warning, size: 16),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.cardBg,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      canAfford ? AppTheme.success : AppTheme.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (canAfford)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text('Redeem ${reward['title']}?'),
                    content: Text(
                      'This will cost $pointsCost points. Your parent will be notified to fulfill this reward.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // TODO: Connect to redemptions table
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reward redeemed! 🎉'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                        child: const Text('Redeem',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Redeem',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}