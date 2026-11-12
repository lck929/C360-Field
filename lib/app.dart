import 'package:c360/core/routing/app_router.dart';
import 'package:c360/core/theme/app_theme.dart';
import 'package:c360/core/theme/theme_mode_controller.dart';
import 'package:c360/features/sync/presentation/providers/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(syncProvider, (_, _) {});
    return MaterialApp.router(
      title: 'C360 Field',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    );
  }
}
