import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../services/data_service.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dataService = DataService();
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _family;
  bool _isLoading = true;

  bool _taskAssignments = true;
  bool _taskCompletions = true;
  bool _transferRequests = true;
  bool _rewards = true;
  bool _dailySummary = false;

  final List<Map<String, dynamic>> _avatars = [
    {'emoji': '👨', 'label': 'Dad'},
    {'emoji': '👩', 'label': 'Mom'},
    {'emoji': '👦', 'label': 'Son'},
    {'emoji': '👧', 'label': 'Daughter'},
    {'emoji': '👴', 'label': 'Grandpa'},
    {'emoji': '👵', 'label': 'Grandma'},
  ];

  int _selectedAvatar = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _dataService.getCurrentUser();
    final family = await _dataService.getCurrentFamily();
    setState(() {
      _currentUser = user;
      _family = family;
      _isLoading = false;
      // Set selected avatar based on current avatar
      if (user != null) {
        final avatarIndex = _avatars
            .indexWhere((a) => a['emoji'] == user['avatar']);
        if (avatarIndex != -1) _selectedAvatar = avatarIndex;
      }
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
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

    final name = _currentUser?['name'] ?? 'User';
    final role = _currentUser?['role'] ?? 'Member';
    final familyName = _family?['name'] ?? 'Your Family';
    final joinCode = _family?['join_code'] ?? '------';
    final avatar = _currentUser?['avatar'] ?? '👤';

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
                    colors: [AppTheme.primary, AppTheme.secondary],
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
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(avatar,
                            style: const TextStyle(fontSize: 44)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$role • $familyName',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile section
                    _sectionTitle('👤 Profile'),
                    const SizedBox(height: 10),
                    _settingsCard(
                      children: [
                        _settingsRow(
                          icon: Icons.person_outline,
                          title: 'Your Name',
                          value: name,
                          onTap: () {},
                        ),
                        _divider(),
                        _settingsRow(
                          icon: Icons.shield_outlined,
                          title: 'Role',
                          value: role,
                          onTap: null,
                        ),
                        _divider(),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Avatar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textDark,
                                  )),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 70,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _avatars.length,
                                  itemBuilder: (context, index) {
                                    final isSelected =
                                        _selectedAvatar == index;
                                    return GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedAvatar = index),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                            right: 10),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppTheme.primary
                                                    : AppTheme.cardBg,
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                                border: isSelected
                                                    ? Border.all(
                                                        color: AppTheme.primary,
                                                        width: 2)
                                                    : null,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _avatars[index]['emoji'],
                                                  style: const TextStyle(
                                                      fontSize: 24),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _avatars[index]['label'],
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: isSelected
                                                    ? AppTheme.primary
                                                    : AppTheme.textMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Family section
                    _sectionTitle('👨‍👩‍👧‍👦 Family'),
                    const SizedBox(height: 10),
                    _settingsCard(
                      children: [
                        _settingsRow(
                          icon: Icons.home_outlined,
                          title: 'Family Name',
                          value: familyName,
                          onTap: () {},
                        ),
                        _divider(),
                        _settingsRow(
                          icon: Icons.key_outlined,
                          title: 'Family Join Code',
                          value: joinCode,
                          onTap: () {
                            // Copy to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Join code: $joinCode'),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Notifications
                    _sectionTitle('🔔 Notifications'),
                    const SizedBox(height: 10),
                    _settingsCard(
                      children: [
                        _toggleRow(
                          title: 'Task Assignments',
                          subtitle: 'Get notified when tasks are assigned',
                          value: _taskAssignments,
                          onChanged: (val) =>
                              setState(() => _taskAssignments = val),
                        ),
                        _divider(),
                        _toggleRow(
                          title: 'Task Completions',
                          subtitle: 'Updates when tasks are completed',
                          value: _taskCompletions,
                          onChanged: (val) =>
                              setState(() => _taskCompletions = val),
                        ),
                        _divider(),
                        _toggleRow(
                          title: 'Transfer Requests',
                          subtitle: 'When someone sends you a task',
                          value: _transferRequests,
                          onChanged: (val) =>
                              setState(() => _transferRequests = val),
                        ),
                        _divider(),
                        _toggleRow(
                          title: 'Rewards',
                          subtitle: 'Reward unlocks and redemptions',
                          value: _rewards,
                          onChanged: (val) =>
                              setState(() => _rewards = val),
                        ),
                        _divider(),
                        _toggleRow(
                          title: 'Daily Summary',
                          subtitle: 'Daily progress report',
                          value: _dailySummary,
                          onChanged: (val) =>
                              setState(() => _dailySummary = val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // About
                    _sectionTitle('ℹ️ About'),
                    const SizedBox(height: 10),
                    _settingsCard(
                      children: [
                        _settingsRow(
                          icon: Icons.info_outline,
                          title: 'Version',
                          value: '1.0.0',
                          onTap: null,
                        ),
                        _divider(),
                        _settingsRow(
                          icon: Icons.update,
                          title: 'Last Updated',
                          value: 'April 2026',
                          onTap: null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Sign out
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout,
                            color: AppTheme.error),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark,
          )),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMedium)),
          if (onTap != null)
            const Icon(Icons.chevron_right,
                color: AppTheme.textLight, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark,
          )),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textMedium)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primary,
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }
}