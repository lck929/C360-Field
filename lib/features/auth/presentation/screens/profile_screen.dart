import 'package:c360/core/di/core_providers.dart';
import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/core/theme/theme_mode_controller.dart';
import 'package:c360/core/widgets/avatar.dart';
import 'package:c360/core/widgets/screen_header.dart';
import 'package:c360/features/attendance/presentation/providers/records_providers.dart';
import 'package:c360/features/auth/presentation/providers/auth_controller.dart';
import 'package:c360/features/auth/presentation/widgets/mock_server_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final pending = ref.read(queuedRecordsProvider).length;
    if (pending > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign out?'),
          content: Text(
            '$pending ${pending == 1 ? 'record hasn’t' : 'records haven’t'} synced yet. '
            'They stay on this phone and sync the next time you sign in.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(authProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(employeeProvider);
    if (employee == null) return const SizedBox.shrink();
    final p = context.palette;
    final config = ref.watch(configProvider);
    final info = {
      'Trade': employee.trade.isEmpty ? '—' : employee.trade,
      'Project': employee.projectName,
      'Shift': employee.shiftLabel,
      'Face enrolled': employee.faceEnrolled ? 'Yes' : 'Not yet',
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            const ScreenHeader(title: 'Profile'),
            const SizedBox(height: 18),
            Row(
              children: [
                Avatar(initials: employee.initials, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                      Text(employee.employeeId, style: TextStyle(color: p.mutedForeground)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: Column(
                children: [
                  for (final entry in info.entries)
                    ListTile(
                      dense: true,
                      title: Text(entry.key, style: TextStyle(color: p.mutedForeground, fontSize: 14)),
                      trailing: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {ref.watch(themeModeProvider)},
              onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
            ),
            if (config.useMockApi) ...[
              const SizedBox(height: 26),
              Text('Mock server', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Test conditions for the local mock API. Not shown when connected to the real API.',
                style: TextStyle(fontSize: 13, color: p.mutedForeground),
              ),
              const SizedBox(height: 10),
              const MockServerPanel(),
            ],
            const SizedBox(height: 28),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: p.destructive),
              onPressed: () => _signOut(context, ref),
              child: const Text('Sign out'),
            ),
            const SizedBox(height: 18),
            Text(
              'C360 Field ${config.appVersion}${config.useMockApi ? ', mock API' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: p.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
