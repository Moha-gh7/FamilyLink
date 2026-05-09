import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/theme_provider.dart';
import '../services/data_service.dart';
import '../widgets/skeleton_loader.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _dataService = DataService();
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _family;
  List<Map<String, dynamic>> _familyMembers = [];
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
    final members = await _dataService.getFamilyMembers();
    setState(() {
      _currentUser = user;
      _family = family;
      _familyMembers = members;
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
    final screenContext = context;
    await showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(dialogContext);
                final success = await _dataService.updateUserName(newName);
                if (success && mounted) {
                  setState(() => _currentUser?['name'] = newName);
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    SnackBar(
                      content: const Text('Name updated successfully!'),
                      backgroundColor: Theme.of(screenContext).colorScheme.primary,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(screenContext).colorScheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _editFamilyName(String currentName, String familyId) async {
    final controller = TextEditingController(text: currentName);
    final screenContext = context;
    await showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(dialogContext);
                final success = await _dataService.updateFamilyName(familyId, newName);
                if (success && mounted) {
                  setState(() => _family?['name'] = newName);
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    SnackBar(
                      content: const Text('Family name updated successfully!'),
                      backgroundColor: Theme.of(screenContext).colorScheme.primary,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(screenContext).colorScheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _copyJoinCode(String joinCode) async {
    await Clipboard.setData(ClipboardData(text: joinCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Join code copied: $joinCode'),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
        SnackBar(
          content: const Text('Avatar updated!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 1),
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
                      // Manage Family Access (parents only)
                      if (_currentUser?['role'] == 'Parent') ...[
                        _sectionTitle('👥 Manage Family Access'),
                        const SizedBox(height: 6),
                        const Text(
                          'Grant a family member access to approve requests',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMedium),
                        ),
                        const SizedBox(height: 10),
                        _buildManageFamilyCard(),
                        const SizedBox(height: 20),
                      ],
                      // Notifications
                      _sectionTitle('🔔 Notifications'),
                      const SizedBox(height: 10),
                      _buildNotificationsCard(),
                      const SizedBox(height: 20),
                      // Theme picker
                      _sectionTitle('🎨 App Theme'),
                      const SizedBox(height: 10),
                      _buildThemePicker(),
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
                                    ? Theme.of(context).colorScheme.primary
                                    : AppTheme.cardBg,
                                borderRadius:
                                    BorderRadius.circular(22),
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(context).colorScheme.primary,
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
                                    ? Theme.of(context).colorScheme.primary
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
          leading: Icon(Icons.key_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
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
                  color: Theme.of(context).colorScheme.primary,
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

  Widget _buildThemePicker() {
    final selectedIndex = ref.watch(themeIndexProvider);
    return _settingsCard(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: AppTheme.themes.asMap().entries.map((entry) {
                final i = entry.key;
                final config = entry.value;
                final isSelected = selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(themeIndexProvider.notifier).state = i,

                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [config.primary, config.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: isSelected
                                ? Border.all(
                                    color: config.primary, width: 3)
                                : Border.all(
                                    color: Colors.transparent, width: 3),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: config.primary.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 22)
                              : Center(
                                  child: Text(config.emoji,
                                      style:
                                          const TextStyle(fontSize: 20))),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          config.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? config.primary
                                : AppTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildManageFamilyCard() {
    final others = _familyMembers
        .where((m) => m['id'] != _currentUser?['id'])
        .toList();

    if (others.isEmpty) {
      return _settingsCard(children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No other family members yet',
              style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
        ),
      ]);
    }

    List<Widget> rows = [];
    for (int i = 0; i < others.length; i++) {
      final member = others[i];
      final isParent = member['role'] == 'Parent';
      final canApprove = isParent || member['can_approve'] == true;

      rows.add(SwitchListTile(
        secondary: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Center(
            child: Text(member['avatar'] ?? '👤',
                style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          member['name'] ?? '',
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role selector
            Row(
              children: [
                const Text('Role: ',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                GestureDetector(
                  onTap: () async {
                    final newRole = member['role'] == 'Parent' ? 'Child' : 'Parent';
                    final success = await _dataService.updateMemberRole(member['id'], newRole);
                    if (success && mounted) {
                      setState(() => member['role'] = newRole);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${member['name']} is now a $newRole'),
                        backgroundColor: AppTheme.success,
                      ));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: member['role'] == 'Parent'
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                          : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: member['role'] == 'Parent'
                            ? Theme.of(context).colorScheme.primary
                            : AppTheme.textLight,
                      ),
                    ),
                    child: Text(
                      '${member['role'] ?? 'Child'} ✎',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: member['role'] == 'Parent'
                            ? Theme.of(context).colorScheme.primary
                            : AppTheme.textMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              canApprove ? 'Can approve requests ✅' : 'No approval access',
              style: TextStyle(
                  fontSize: 11,
                  color: canApprove ? AppTheme.success : AppTheme.textMedium),
            ),
          ],
        ),
        value: canApprove,
        onChanged: (val) async {
          final success = await _dataService.updateDelegate(member['id'], val);
          if (success && mounted) {
            setState(() => member['can_approve'] = val);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(val
                    ? '${member['name']} can now approve requests'
                    : '${member['name']} approval access removed'),
                backgroundColor: val ? AppTheme.success : AppTheme.error,
              ),
            );
          }
        },
        activeColor: Theme.of(context).colorScheme.primary,
      ));
      if (i < others.length - 1) rows.add(_divider());
    }

    return _settingsCard(children: rows);
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
            color: Colors.black.withOpacity(0.04),
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
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
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
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }
}