import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

final themeIndexProvider = NotifierProvider<ThemeNotifier, int>(ThemeNotifier.new);
