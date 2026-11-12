import 'package:c360/core/di/core_providers.dart';
import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/core/utils/formatters.dart';
import 'package:c360/core/widgets/empty_state.dart';
import 'package:c360/core/widgets/result_icon.dart';
import 'package:c360/core/widgets/screen_header.dart';
import 'package:c360/features/attendance/presentation/providers/records_providers.dart';
import 'package:c360/features/attendance/presentation/widgets/status_chip.dart';
import 'package:c360/features/sync/presentation/providers/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final online = ref.watch(isOnlineProvider).value ?? true;
    final queue = ref.watch(queuedRecordsProvider);
    final sync = ref.watch(syncProvider);
    final lastSynced = sync.lastSyncedAt;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            ScreenHeader(
              title: 'Sync',
              subtitle: online ? 'Online. Records sync automatically.' : 'You’re offline. Records will sync when you reconnect.',
            ),
            const SizedBox(height: 16),
            if (queue.isEmpty)
              EmptyState(
                icon: const ResultIcon(tone: Tone.success, size: 64),
                title: 'Everything is synced',
                message: lastSynced == null ? 'Nothing is waiting on this phone.' : 'Last synced at ${formatHm(lastSynced)}.',
              )
            else ...[
              for (final record in queue)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      title: Text(record.type.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        [
                          '${formatDay(record.capturedAt)}, ${formatHm(record.capturedAt)}, with photo',
                          if (record.attempts > 0 && record.error != null)
                            record.nextAttemptAt == null
                                ? '${record.error}.'
                                : '${record.error}. Retrying at ${formatHm(record.nextAttemptAt!)}.',
                        ].join('\n'),
                        style: TextStyle(fontSize: 13, color: p.mutedForeground),
                      ),
                      trailing: StatusChip(status: record.status),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('syncNow'),
                onPressed: !online || sync.syncing ? null : () => ref.read(syncProvider.notifier).sync(force: true),
                child: Text(sync.syncing ? 'Syncing…' : 'Sync now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
