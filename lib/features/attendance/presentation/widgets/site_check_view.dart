import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/core/widgets/result_icon.dart';
import 'package:c360/core/widgets/screen_header.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/presentation/providers/check_state.dart';
import 'package:c360/features/site_check/domain/entities/wifi_reading.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SiteCheckView extends StatelessWidget {
  const SiteCheckView({super.key, required this.type, required this.state, required this.onRetry});

  final AttendanceType type;
  final CheckState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = state.step == CheckStep.wifiFailed;
    return ListView(
      children: [
        ScreenHeader(
          title: failed ? 'You can’t ${type.label.toLowerCase()} yet' : 'Confirming you’re on site',
          subtitle: failed ? 'Fix the issue below, then check again.' : 'This takes a few seconds, before your photo is taken.',
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: ResultIcon(
              size: 28,
              tone: failed
                  ? Tone.failure
                  : state.wifiPassed
                      ? Tone.success
                      : Tone.loading,
            ),
            title: const Text('Site Wi-Fi', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(state.detail ?? 'Checking…', style: TextStyle(color: context.palette.mutedForeground)),
          ),
        ),
        if (failed) ...[
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Check again')),
          if (state.problem == WifiProblem.permissionBlocked) ...[
            const SizedBox(height: 10),
            const OutlinedButton(onPressed: openAppSettings, child: Text('Open Settings')),
          ],
        ],
      ],
    );
  }
}
