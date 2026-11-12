enum AttendanceType {
  checkIn('IN'),
  checkOut('OUT');

  const AttendanceType(this.api);

  final String api;

  String get label => this == checkIn ? 'Check in' : 'Check out';

  static AttendanceType fromApi(String value) => value.toUpperCase() == 'OUT' ? checkOut : checkIn;
}

enum SyncStatus { pending, syncing, verified, rejected }

class AttendanceRecord {
  const AttendanceRecord({
    required this.clientId,
    required this.employeeId,
    required this.type,
    required this.capturedAt,
    this.bssid = '',
    this.selfie = '',
    this.status = SyncStatus.pending,
    this.attempts = 0,
    this.nextAttemptAt,
    this.error,
    this.errorCode,
    this.serverId,
  });

  final String clientId;
  final String employeeId;
  final AttendanceType type;
  final DateTime capturedAt;
  final String bssid;
  final String selfie;
  final SyncStatus status;
  final int attempts;
  final DateTime? nextAttemptAt;
  final String? error;
  final String? errorCode;
  final String? serverId;

  bool get isQueued => status == SyncStatus.pending || status == SyncStatus.syncing;

  AttendanceRecord copyWith({
    SyncStatus? status,
    int? attempts,
    DateTime? nextAttemptAt,
    bool clearRetry = false,
    String? error,
    String? errorCode,
    String? serverId,
  }) =>
      AttendanceRecord(
        clientId: clientId,
        employeeId: employeeId,
        type: type,
        capturedAt: capturedAt,
        bssid: bssid,
        selfie: selfie,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        nextAttemptAt: clearRetry ? null : nextAttemptAt ?? this.nextAttemptAt,
        error: clearRetry ? error : error ?? this.error,
        errorCode: errorCode ?? this.errorCode,
        serverId: serverId ?? this.serverId,
      );
}
