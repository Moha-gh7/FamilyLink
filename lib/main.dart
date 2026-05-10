import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    const ProviderScope(
      child: FamilyLinkApp(),
    ),
  );
}

class FamilyLinkApp extends ConsumerStatefulWidget {
  const FamilyLinkApp({super.key});

  @override
  ConsumerState<FamilyLinkApp> createState() => _FamilyLinkAppState();
}

class _FamilyLinkAppState extends ConsumerState<FamilyLinkApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeIndex = ref.watch(themeIndexProvider);
    final config = AppTheme.themes[themeIndex];
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'FamilyLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(config),
      home: Supabase.instance.client.auth.currentSession != null
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
