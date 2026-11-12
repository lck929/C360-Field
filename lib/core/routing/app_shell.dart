import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/features/attendance/presentation/providers/records_providers.dart';
import 'package:c360/features/sync/presentation/providers/sync_controller.dart';
import 'package:c360/features/sync/presentation/providers/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (next.notice == null || next.noticeId == previous?.noticeId) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next.notice!), duration: const Duration(seconds: 3)));
    });

    final pending = ref.watch(queuedRecordsProvider).length;
    Widget syncIcon(IconData icon) => Badge(
          isLabelVisible: pending > 0,
          backgroundColor: context.palette.warning,
          label: Text('$pending'),
          child: Icon(icon),
        );

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.palette.border))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            const NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: syncIcon(Icons.cloud_upload_outlined),
              selectedIcon: syncIcon(Icons.cloud_upload),
              label: 'Sync',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
