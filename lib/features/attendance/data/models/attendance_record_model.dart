import 'package:c360/features/attendance/domain/entities/attendance_record.dart';

abstract final class AttendanceRecordModel {
  static AttendanceRecord fromJson(Map<String, dynamic> json) => AttendanceRecord(
        clientId: json['clientId'] as String,
        employeeId: json['employeeId'] as String,
        type: AttendanceType.fromApi(json['type'] as String),
        capturedAt: DateTime.parse(json['capturedAt'] as String).toLocal(),
        bssid: json['bssid'] as String? ?? '',
        selfie: json['selfie'] as String? ?? '',
        status: SyncStatus.values.asNameMap()[json['status']] ?? SyncStatus.pending,
        attempts: json['attempts'] as int? ?? 0,
        nextAttemptAt: DateTime.tryParse(json['nextAttemptAt'] as String? ?? '')?.toLocal(),
        error: json['error'] as String?,
        errorCode: json['errorCode'] as String?,
        serverId: json['serverId'] as String?,
      );

  static Map<String, dynamic> toJson(AttendanceRecord r) => {
        'clientId': r.clientId,
        'employeeId': r.employeeId,
        'type': r.type.api,
        'capturedAt': r.capturedAt.toUtc().toIso8601String(),
        'bssid': r.bssid,
        'selfie': r.selfie,
        'status': r.status.name,
        'attempts': r.attempts,
        'nextAttemptAt': r.nextAttemptAt?.toUtc().toIso8601String(),
        'error': r.error,
        'errorCode': r.errorCode,
        'serverId': r.serverId,
      };

  static AttendanceRecord fromServer(Map<String, dynamic> json, String employeeId) => AttendanceRecord(
        clientId: json['id'] as String,
        serverId: json['id'] as String,
        employeeId: employeeId,
        type: AttendanceType.fromApi(json['type'] as String),
        capturedAt: DateTime.parse(json['capturedAt'] as String).toLocal(),
        status: switch ((json['status'] as String?)?.toUpperCase()) {
          'VERIFIED' => SyncStatus.verified,
          'REJECTED' || 'NOT_MATCHED' => SyncStatus.rejected,
          _ => SyncStatus.pending,
        },
      );
}
