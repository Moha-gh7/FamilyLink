import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/data_service.dart';
import '../widgets/skeleton_loader.dart';
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

  Future<void> _editName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Your Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final success = await _dataService.updateUserName(newName);
                if (success && mounted) {
                  setState(() {
                    _currentUser?['name'] = newName;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name updated successfully!'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _editFamilyName(String currentName, String familyId) async {
    final controller = TextEditingController(text: currentName);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Family Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter family name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final success = await _dataService.updateFamilyName(familyId, newName);
                if (success && mounted) {
                  setState(() {
                    _family?['name'] = newName;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Family name updated successfully!'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _copyJoinCode(String joinCode) async {
    await Clipboard.setData(ClipboardData(text: joinCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Join code copied: $joinCode'),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveAvatarChange(int newIndex) async {
    final newAvatar = _avatars[newIndex]['emoji'];
    final success = await _dataService.updateUserAvatar(newAvatar);
    if (success && mounted) {
      setState(() {
        _selectedAvatar = newIndex;
        _currentUser?['avatar'] = newAvatar;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar updated!'),
          backgroundColor: AppTheme.primary,
          duration: Duration(seconds: 1),
        ),
      );
    }
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _isLoading
                  ? SkeletonProfileHeader()
                  : _buildHeader(context),

              if (!_isLoading)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile section
                      _sectionTitle('👤 Profile'),
                      const SizedBox(height: 10),
                      _buildProfileCard(),
                      const SizedBox(height: 20),
                      // Family section
                      _sectionTitle('👨‍👩‍👧‍👦 Family'),
                      const SizedBox(height: 10),
                      _buildFamilyCard(),
                      const SizedBox(height: 20),
                      // Notifications
                      _sectionTitle('🔔 Notifications'),
                      const SizedBox(height: 10),
                      _buildNotificationsCard(),
                      const SizedBox(height: 20),
                      // About
                      _sectionTitle('ℹ️ About'),
                      const SizedBox(height: 10),
                      _buildAboutCard(),
                      const SizedBox(height: 20),
                      // Sign out
                      _buildSignOutButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('👤 Profile'),
                      const SizedBox(height: 10),
                      SkeletonSettingsCard(itemCount: 3),
                      const SizedBox(height: 20),
                      _sectionTitle('👨‍👩‍👧‍👦 Family'),
                      const SizedBox(height: 10),
                      SkeletonSettingsCard(itemCount: 2),
                      const SizedBox(height: 20),
                      _sectionTitle('🔔 Notifications'),
                      const SizedBox(height: 10),
                      SkeletonSettingsCard(itemCount: 5),
                      const SizedBox(height: 20),
                      _sectionTitle('ℹ️ About'),
                      const SizedBox(height: 10),
                      SkeletonSettingsCard(itemCount: 2),
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

  Widget _buildHeader(BuildContext context) {
    final name = _currentUser?['name'] ?? 'User';
    final role = _currentUser?['role'] ?? 'Member';
    final familyName = _family?['name'] ?? 'Your Family';
    final avatar = _currentUser?['avatar'] ?? '👤';

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
    );
  }

  Widget _buildProfileCard() {
    final name = _currentUser?['name'] ?? 'User';
    final role = _currentUser?['role'] ?? 'Member';

    return _settingsCard(
      children: [
        _settingsRow(
          icon: Icons.person_outline,
          title: 'Your Name',
          value: name,
          onTap: () => _editName(name),
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
                      onTap: () => _saveAvatarChange(index),
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
    );
  }

  Widget _buildFamilyCard() {
    final familyName = _family?['name'] ?? 'Your Family';
    final joinCode = _family?['join_code'] ?? '------';

    return _settingsCard(
      children: [
        _settingsRow(
          icon: Icons.home_outlined,
          title: 'Family Name',
          value: familyName,
          onTap: () => _editFamilyName(familyName, _family?['id'] ?? ''),
        ),
        _divider(),
        ListTile(
          leading: Icon(Icons.key_outlined, color: AppTheme.primary, size: 22),
          title: const Text('Family Join Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              )),
          trailing: SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(joinCode,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textMedium)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  color: AppTheme.primary,
                  onPressed: () => _copyJoinCode(joinCode),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsCard() {
    return _settingsCard(
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
    );
  }

  Widget _buildAboutCard() {
    return _settingsCard(
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
          value: 'May 2026',
          onTap: null,
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
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