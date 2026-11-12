import 'package:c360/core/di/core_providers.dart';
import 'package:c360/core/error/error_codes.dart';
import 'package:c360/features/attendance/di/attendance_providers.dart';
import 'package:c360/features/attendance/domain/entities/attendance_record.dart';
import 'package:c360/features/attendance/presentation/providers/check_state.dart';
import 'package:c360/features/attendance/presentation/providers/history_notifier.dart';
import 'package:c360/features/auth/presentation/providers/auth_controller.dart';
import 'package:c360/features/site_check/di/site_check_providers.dart';
import 'package:c360/features/site_check/domain/entities/wifi_reading.dart';
import 'package:c360/features/site_check/presentation/wifi_messages.dart';
import 'package:c360/features/sync/presentation/providers/sync_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckController extends Notifier<CheckState> {
  CheckController(this.type);

  static const noFaceMessage = 'No face found. Face the camera in good light and try again.';

  final AttendanceType type;
  String? _bssid;
  String? _ssid;

  @override
  CheckState build() {
    Future.microtask(runChecks);
    return const CheckState(CheckStep.checking);
  }

  Future<bool> _online() => ref.read(connectivityProvider).isOnline();

  Future<void> runChecks() async {
    state = const CheckState(CheckStep.checking);
    if (await _online()) {
      await ref.read(authProvider.notifier).refreshProfile().timeout(const Duration(seconds: 5), onTimeout: () {});
    }
    final employee = ref.mounted ? ref.read(employeeProvider) : null;
    if (employee == null) return;

    final result = await ref.read(checkSiteWifiProvider)(employee.wifiBssids);
    if (!ref.mounted) return;

    final problem = result.problem;
    if (problem != null) {
      state = CheckState(
        CheckStep.wifiFailed,
        problem: problem,
        detail: wifiMessage(problem, ssid: result.reading.ssid, projectName: employee.projectName),
      );
      return;
    }
    _bssid = result.reading.bssid;
    _ssid = result.reading.ssid;
    state = CheckState(CheckStep.checking, wifiPassed: true, detail: '${_ssid ?? 'Site Wi-Fi'}, ${_bssid!.toUpperCase()}');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (ref.mounted) state = const CheckState(CheckStep.camera);
  }

  void retake() => state = const CheckState(CheckStep.camera);

  Future<void> submitPhoto(String photoPath) async {
    final employee = ref.read(employeeProvider);
    final bssid = _bssid;
    if (employee == null || bssid == null) return;

    final online = await _online();
    if (!ref.mounted) return;
    state = CheckState(CheckStep.submitting, online: online);

    final AttendanceRecord captured;
    try {
      captured = await ref.read(captureAttendanceProvider)(
        employeeId: employee.employeeId,
        type: type,
        photoPath: photoPath,
        bssid: bssid,
      );
    } catch (_) {
      if (ref.mounted) state = const CheckState(CheckStep.camera, cameraError: 'Couldn’t save the photo. Try again.');
      return;
    }

    if (online) await ref.read(syncProvider.notifier).sync(force: true, silent: true);
    if (!ref.mounted) return;

    final saved = await ref.read(getRecordProvider)(captured.clientId);
    if (!ref.mounted) return;
    if (saved == null || saved.isQueued) {
      state = CheckState(CheckStep.result, outcome: CheckOutcome.savedOffline, at: captured.capturedAt);
    } else if (saved.status == SyncStatus.verified) {
      state = CheckState(CheckStep.result, outcome: CheckOutcome.verified, at: captured.capturedAt);
    } else {
      await ref.read(discardRecordProvider)(saved);
      if (ref.mounted) state = _rejected(saved, employee.projectName);
    }
  }

  CheckState _rejected(AttendanceRecord record, String projectName) {
    switch (record.errorCode) {
      case ErrorCodes.noFaceFound:
        return const CheckState(CheckStep.camera, cameraError: noFaceMessage);
      case ErrorCodes.notOnSiteNetwork:
        return CheckState(
          CheckStep.wifiFailed,
          problem: WifiProblem.notRegistered,
          detail: wifiMessage(WifiProblem.notRegistered, ssid: _ssid, projectName: projectName),
        );
      case ErrorCodes.sequenceError:
        ref.invalidate(historyProvider);
        return CheckState(
          CheckStep.result,
          outcome: CheckOutcome.alreadyRecorded,
          message: type == AttendanceType.checkIn
              ? 'You’re already checked in today. Your attendance has been refreshed from the server.'
              : 'There’s no open check-in to close today. Your attendance has been refreshed from the server.',
        );
      case ErrorCodes.faceNotMatched:
        return const CheckState(CheckStep.result, outcome: CheckOutcome.faceNotMatched);
      default:
        return CheckState(CheckStep.result, outcome: CheckOutcome.failed, message: record.error);
    }
  }
}

final checkProvider =
    NotifierProvider.autoDispose.family<CheckController, CheckState, AttendanceType>(CheckController.new);
