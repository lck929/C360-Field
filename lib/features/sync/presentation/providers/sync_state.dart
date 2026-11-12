class SyncState {
  const SyncState({this.syncing = false, this.lastSyncedAt, this.notice, this.noticeId = 0});

  final bool syncing;
  final DateTime? lastSyncedAt;
  final String? notice;
  final int noticeId;

  SyncState copyWith({bool? syncing, DateTime? lastSyncedAt, String? notice}) => SyncState(
        syncing: syncing ?? this.syncing,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        notice: notice ?? this.notice,
        noticeId: notice == null ? noticeId : noticeId + 1,
      );
}
