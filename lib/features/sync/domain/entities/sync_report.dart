enum SyncStop { done, waiting, offline, unauthorized }

class SyncReport {
  const SyncReport({this.verified = 0, this.rejected = 0, this.stop = SyncStop.done, this.retryAt});

  final int verified;
  final int rejected;
  final SyncStop stop;
  final DateTime? retryAt;

  int get processed => verified + rejected;

  SyncReport then(SyncReport next) => SyncReport(
        verified: verified + next.verified,
        rejected: rejected + next.rejected,
        stop: next.stop,
        retryAt: next.retryAt,
      );
}
