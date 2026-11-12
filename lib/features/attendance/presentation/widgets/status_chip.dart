import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final SyncStatus status;

  static String labelFor(SyncStatus status) => switch (status) {
        SyncStatus.verified => 'Verified',
        SyncStatus.pending => 'Waiting to sync',
        SyncStatus.syncing => 'Syncing',
        SyncStatus.rejected => 'Not matched',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (background, foreground) = switch (status) {
      SyncStatus.verified => (p.success.withValues(alpha: 0.12), p.success),
      SyncStatus.pending => (p.warning.withValues(alpha: 0.14), p.warning),
      SyncStatus.syncing => (Brand.gold.withValues(alpha: 0.16), p.accentForeground),
      SyncStatus.rejected => (p.destructive.withValues(alpha: 0.10), p.destructive),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        labelFor(status),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}
