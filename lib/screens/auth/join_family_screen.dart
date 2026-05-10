import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';



class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _authService = AuthService();
bool _isLoading = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedEmoji = '🦸';

  static const _emojiCategories = [
    {'label': '🦸 Heroes', 'emojis': ['🦸','🦹','🧙','🧚','🧜','🧝','🧞','🧟','👻','🤖','👽','🎅','🥷','🧑‍🚀','🦄','🐲','🧛','🧌','👾','🎃']},
    {'label': '🐾 Animals', 'emojis': ['🦊','🐺','🦁','🐯','🐻','🐼','🐨','🐸','🦝','🐧','🦅','🦉','🐬','🦈','🦋','🦓','🦒','🦘','🦔','🐙']},
    {'label': '⚡ Action', 'emojis': ['🏄','🧗','🤸','🏇','🤺','⛷️','🏊','🚵','🤼','🥊','🏋️','🤾','🧘','🪂','🏌️','🤽','🚴','🤙','🏹','🎿']},
    {'label': '🎭 Roles', 'emojis': ['🧑‍🍳','🧑‍🎨','🧑‍🔬','🧑‍💻','🧑‍🏫','🧑‍⚕️','🧑‍🌾','🧑‍🔧','🧑‍✈️','🧑‍🎤','🧑‍🎓','🕵️','👮','💂','🧑‍🚒','🤴','👸','🫅','🥸','🤠']},
  ];

Future<void> _joinFamily() async {
  if (_codeController.text.trim().isEmpty ||
      _nameController.text.trim().isEmpty ||
      _emailController.text.trim().isEmpty ||
      _passwordController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all fields')),
    );
    return;
  }
  setState(() => _isLoading = true);
  final result = await _authService.joinFamily(
    joinCode: _codeController.text.trim(),
    name: _nameController.text.trim(),
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
    avatar: _selectedEmoji,
  );
  if (!mounted) return;
  setState(() => _isLoading = false);
  if (result['success'] == true) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Failed to join family')),
    );
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
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

              // Title
              const Text(
                'Join Your Family',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your family code to join',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMedium,
                ),
              ),

              const SizedBox(height: 32),

              // Family join code box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.group, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Family Join Code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: AppTheme.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'XXXXXX',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: AppTheme.primary.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ask the family creator for this code',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Avatar picker
              const Text('Choose your avatar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
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

              // Your name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'e.g. Yusuf',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppTheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Join button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
onPressed: _isLoading ? null : _joinFamily,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Join Family',
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