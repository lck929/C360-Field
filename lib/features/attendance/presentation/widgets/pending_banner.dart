import 'package:c360/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

class PendingBanner extends StatelessWidget {
  const PendingBanner({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final warning = context.palette.warning;
    return Material(
      color: warning.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: warning.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.cloud_upload_outlined, size: 18, color: warning),
        trailing: Icon(Icons.chevron_right, size: 18, color: warning),
        title: Text(
          '$count ${count == 1 ? 'record is' : 'records are'} waiting to sync',
          style: const TextStyle(fontSize: 13.5),
        ),
      ),
    );
  }
}
