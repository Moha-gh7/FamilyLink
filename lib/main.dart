import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'supabase_config.dart';
import 'screens/auth/login_screen.dart';

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

class FamilyLinkApp extends ConsumerWidget {
  const FamilyLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeIndex = ref.watch(themeIndexProvider);
    final config = AppTheme.themes[themeIndex];
    return MaterialApp(
      title: 'FamilyLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(config),
      home: Supabase.instance.client.auth.currentSession != null
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
