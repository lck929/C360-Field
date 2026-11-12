import 'package:c360/core/routing/routes.dart';
import 'package:c360/core/widgets/result_icon.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/presentation/providers/check_controller.dart';
import 'package:c360/features/attendance/presentation/providers/check_state.dart';
import 'package:c360/features/attendance/presentation/widgets/check_message.dart';
import 'package:c360/features/attendance/presentation/widgets/selfie_camera.dart';
import 'package:c360/features/attendance/presentation/widgets/site_check_view.dart';
import 'package:c360/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CheckScreen extends ConsumerWidget {
  const CheckScreen({super.key, required this.type});

  final AttendanceType type;

  void _close(BuildContext context) => context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkProvider(type));
    final controller = ref.read(checkProvider(type).notifier);

    if (state.step == CheckStep.camera) {
      return SelfieCamera(
        title: type.label,
        error: state.cameraError,
        onCancel: () => _close(context),
        onCaptured: controller.submitPhoto,
      );
    }

    final checking = state.step == CheckStep.checking || state.step == CheckStep.wifiFailed;

    return PopScope(
      canPop: state.step != CheckStep.submitting,
      child: Scaffold(
        appBar: checking
            ? AppBar(
                automaticallyImplyLeading: false,
                leadingWidth: 96,
                leading: TextButton(onPressed: () => _close(context), child: const Text('Cancel')),
                title: Text(type.label),
              )
            : null,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            child: checking
                ? SiteCheckView(type: type, state: state, onRetry: controller.runChecks)
                : state.step == CheckStep.submitting
                    ? CheckMessage(
                        tone: Tone.loading,
                        title: state.online ? 'Verifying your photo' : 'Saving on this phone',
                        body: state.online
                            ? 'Matching your selfie with your enrolled face.'
                            : 'No network. Your record will be sent when you’re back online.',
                      )
                    : _result(context, ref, state, controller),
          ),
        ),
      ),
    );
  }

  Widget _result(BuildContext context, WidgetRef ref, CheckState state, CheckController controller) {
    final isIn = type == AttendanceType.checkIn;
    final project = ref.watch(employeeProvider)?.projectName ?? 'your project';
    final done = FilledButton(onPressed: () => _close(context), child: const Text('Done'));
    final retry = [
      FilledButton(onPressed: controller.retake, child: const Text('Try again')),
      TextButton(onPressed: () => _close(context), child: const Text('Back to home')),
    ];

    return switch (state.outcome!) {
      CheckOutcome.verified => CheckMessage(
          tone: Tone.success,
          title: isIn ? 'Checked in' : 'Checked out',
          time: state.at,
          body: 'Your attendance is recorded for $project.',
          actions: [done],
        ),
      CheckOutcome.savedOffline => CheckMessage(
          tone: Tone.pending,
          title: 'Saved offline',
          time: state.at,
          body: 'Your ${isIn ? 'check-in' : 'check-out'} is stored on this phone and will be '
              'verified automatically when you’re back online.',
          actions: [done],
        ),
      CheckOutcome.faceNotMatched => CheckMessage(
          tone: Tone.failure,
          title: 'Face didn’t match',
          body: 'Your photo didn’t match your enrolled face. Try again in better light, '
              'or ask your foreman to record your attendance.',
          actions: retry,
        ),
      CheckOutcome.alreadyRecorded => CheckMessage(
          tone: Tone.pending,
          title: 'Already recorded',
          body: state.message ?? 'Today’s attendance has been refreshed from the server.',
          actions: [done],
        ),
      CheckOutcome.failed => CheckMessage(
          tone: Tone.failure,
          title: 'Couldn’t record attendance',
          body: state.message ?? 'Something went wrong. Try again.',
          actions: retry,
        ),
    };
  }
}
