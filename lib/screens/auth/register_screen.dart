import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _familyNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _selectedAvatar = 0;

  String _selectedEmoji = '🦸';

  static const _emojiCategories = [
    {'label': '🦸 Heroes', 'emojis': ['🦸','🦹','🧙','🧚','🧜','🧝','🧞','🧟','👻','🤖','👽','🎅','🥷','🧑‍🚀','🦄','🐲','🧛','🧌','👾','🎃']},
    {'label': '🐾 Animals', 'emojis': ['🦊','🐺','🦁','🐯','🐻','🐼','🐨','🐸','🦝','🐧','🦅','🦉','🐬','🦈','🦋','🦓','🦒','🦘','🦔','🐙']},
    {'label': '⚡ Action', 'emojis': ['🏄','🧗','🤸','🏇','🤺','⛷️','🏊','🚵','🤼','🥊','🏋️','🤾','🧘','🪂','🏌️','🤽','🚴','🤙','🏹','🎿']},
    {'label': '🎭 Roles', 'emojis': ['🧑‍🍳','🧑‍🎨','🧑‍🔬','🧑‍💻','🧑‍🏫','🧑‍⚕️','🧑‍🌾','🧑‍🔧','🧑‍✈️','🧑‍🎤','🧑‍🎓','🕵️','👮','💂','🧑‍🚒','🤴','👸','🫅','🥸','🤠']},
  ];

  @override
  void dispose() {
    _familyNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    // Validate fields
    if (_familyNameController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.createFamily(
      familyName: '${_familyNameController.text.trim()} Family',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      avatar: _selectedEmoji,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      // Show join code to user
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '🎉 Family Created!',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share this code with your family members:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMedium),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result['join_code'],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Write it down — you\'ll need it!',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to Login',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showAvatarPicker(BuildContext context) {
    int selectedCategory = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final emojis = _emojiCategories[selectedCategory]['emojis'] as List<String>;
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Choose Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _emojiCategories.asMap().entries.map((entry) {
                      final isSelected = selectedCategory == entry.key;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedCategory = entry.key),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(entry.value['label'] as String,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppTheme.textMedium)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, crossAxisSpacing: 12, mainAxisSpacing: 12,
                    ),
                    itemCount: emojis.length,
                    itemBuilder: (_, i) {
                      final emoji = emojis[i];
                      final isSelected = _selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedEmoji = emoji);
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Create New Family',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Set up your family account',
                style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
              ),
              const SizedBox(height: 32),

              // Avatar picker
              const Text(
                'Choose your avatar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showAvatarPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 30))),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Avatar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                            Text('Tap to pick a character', style: TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Family name
              TextField(
                controller: _familyNameController,
                decoration: InputDecoration(
                  labelText: 'Family Name',
                  hintText: 'e.g. Al-Hassan',
                  prefixIcon: const Icon(Icons.home_outlined,
                      color: AppTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Your name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'e.g. Ahmed',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.textMedium,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createFamily,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Family',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}