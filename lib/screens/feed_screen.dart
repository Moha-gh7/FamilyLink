import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../services/data_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _dataService = DataService();
  List<Map<String, dynamic>> _feedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    final feed = await _dataService.getActivityFeed();
    setState(() {
      _feedItems = feed;
      _isLoading = false;
    });
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Family Activity Feed',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "See what everyone's been up to",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Feed list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary))
                  : _feedItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.timeline_outlined,
                                  size: 60, color: AppTheme.textLight),
                              const SizedBox(height: 12),
                              const Text(
                                'No activity yet!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMedium,
                                ),
                              ),
                              const Text(
                                'Start creating tasks to see activity here',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFeed,
                          color: AppTheme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _feedItems.length,
                            itemBuilder: (context, index) {
                              return _feedItem(
                                  _feedItems[index], index);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedItem(Map<String, dynamic> item, int index) {
    Color cardColor;
    Color iconColor;
    IconData iconData;
    final type = item['type'] ?? 'assigned';

    switch (type) {
      case 'completed':
        cardColor = const Color(0xFFE8F8F0);
        iconColor = AppTheme.success;
        iconData = Icons.check_circle_outline;
        break;
      case 'reward':
        cardColor = const Color(0xFFF0EEFF);
        iconColor = AppTheme.primary;
        iconData = Icons.card_giftcard_outlined;
        break;
      default:
        cardColor = Colors.white;
        iconColor = AppTheme.textMedium;
        iconData = Icons.assignment_outlined;
    }

    final user = item['user'];
    final avatar = user?['avatar'] ?? '👤';
    final name = user?['name'] ?? 'Unknown';
    final content = item['content'] ?? '';
    final createdAt = item['created_at'] != null
        ? DateTime.parse(item['created_at']).toLocal()
        : DateTime.now();
    final timeAgo = _timeAgo(createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: iconColor, width: 1.5),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            if (index < _feedItems.length - 1)
              Container(width: 2, height: 60, color: AppTheme.cardBg),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(avatar,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: type == 'reward'
                        ? AppTheme.primary
                        : AppTheme.textDark,
                    fontWeight: type == 'reward'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}