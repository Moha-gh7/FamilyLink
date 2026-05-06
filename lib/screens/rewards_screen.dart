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
        ((b['points'] ?? 0) as int).compareTo((a['points'] ?? 0) as int));

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

  Future<void> _showAddRewardDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedEmoji = '🎁';
    int points = 100;
    bool isSaving = false;

    final screenContext = context;

    final emojiOptions = [
      '🎁', '🍦', '🎬', '🎮', '🍕', '🏖️', '📚', '🍔',
      '🎨', '🏆', '🎉', '🛍️', '🍭', '🎯', '🚀', '⭐',
      '🎠', '💆', '🍰', '🎪',
    ];

    final templates = [
      {'emoji': '🍦', 'title': 'Ice Cream Trip', 'desc': 'Family outing to favorite ice cream shop', 'points': 150},
      {'emoji': '🎬', 'title': 'Movie Night', 'desc': 'Choose any movie + popcorn', 'points': 200},
      {'emoji': '🎮', 'title': 'Extra Screen Time', 'desc': '1 hour extra phone/game time', 'points': 100},
      {'emoji': '🍕', 'title': 'Pizza Night', 'desc': 'Pick your favorite pizza toppings', 'points': 175},
      {'emoji': '🎁', 'title': 'Mystery Gift', 'desc': 'A surprise gift from parents', 'points': 500},
      {'emoji': '🏖️', 'title': 'Beach Trip', 'desc': 'A fun day out at the beach', 'points': 300},
      {'emoji': '🍔', 'title': 'Favorite Restaurant', 'desc': 'Dinner at your chosen restaurant', 'points': 250},
      {'emoji': '💆', 'title': 'No Chores Day', 'desc': 'A full day off from chores', 'points': 200},
    ];

    await showDialog(
      context: screenContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Reward', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick templates
                const Text('Quick Templates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMedium)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: templates.map((t) {
                        final isSelected = titleController.text == t['title'];
                        return GestureDetector(
                          onTap: () => setDialogState(() {
                            selectedEmoji = t['emoji'] as String;
                            titleController.text = t['title'] as String;
                            descController.text = t['desc'] as String;
                            points = t['points'] as int;
                          }),
                          child: Container(
                            width: 72,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withOpacity(0.12)
                                  : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(t['emoji'] as String, style: const TextStyle(fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(
                                  t['title'] as String,
                                  style: const TextStyle(fontSize: 9, color: AppTheme.textDark),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Emoji picker
                const Text('Choose Emoji', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMedium)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: emojiOptions.map((e) {
                    final isSelected = selectedEmoji == e;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedEmoji = e),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Points picker
                Row(
                  children: [
                    const Text('Points required:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setDialogState(() { if (points > 10) points -= 10; }),
                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$points', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ),
                    IconButton(
                      onPressed: () => setDialogState(() => points += 10),
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Please enter a title')),
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      final success = await _dataService.createReward(
                        emoji: selectedEmoji,
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        pointsCost: points,
                      );
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      await Future.delayed(Duration.zero);
                      if (!mounted) return;
                      if (success) {
                        _loadData();
                        ScaffoldMessenger.of(screenContext).showSnackBar(
                          const SnackBar(
                            content: Text('Reward added! 🎁'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(screenContext).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to save reward. Check your connection and try again.'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    descController.dispose();
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

    final isParent = _currentUser?['role'] == 'Parent';

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: isParent
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: _showAddRewardDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
                final screenContext = context;
                showDialog(
                  context: screenContext,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text('Redeem ${reward['title']}?'),
                    content: Text(
                      'This will cost $pointsCost points. Your parent will be notified to fulfill this reward.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          final success = await _dataService.redeemReward(
                            rewardTitle: reward['title'] ?? '',
                            pointsCost: pointsCost,
                          );
                          if (!mounted) return;
                          if (success) {
                            _loadData();
                            ScaffoldMessenger.of(screenContext).showSnackBar(
                              const SnackBar(
                                content: Text('Reward redeemed! 🎉 Your parent has been notified.'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(screenContext).showSnackBar(
                              const SnackBar(
                                content: Text('Redemption failed. Try again.'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
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