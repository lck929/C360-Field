import 'package:c360/features/site_check/domain/entities/wifi_reading.dart';

enum CheckStep { checking, wifiFailed, camera, submitting, result }

enum CheckOutcome { verified, savedOffline, faceNotMatched, alreadyRecorded, failed }

class CheckState {
  const CheckState(
    this.step, {
    this.wifiPassed = false,
    this.detail,
    this.problem,
    this.cameraError,
    this.online = true,
    this.outcome,
    this.at,
    this.message,
  });

  final CheckStep step;
  final bool wifiPassed;
  final String? detail;
  final WifiProblem? problem;
  final String? cameraError;
  final bool online;
  final CheckOutcome? outcome;
  final DateTime? at;
  final String? message;
}
