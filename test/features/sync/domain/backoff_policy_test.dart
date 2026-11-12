import 'dart:math';

import 'package:c360/features/sync/domain/policies/backoff_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('doubles from 5 seconds and caps at 10 minutes', () {
    final backoff = BackoffPolicy(jitter: 0);

    expect(backoff.delayFor(1), const Duration(seconds: 5));
    expect(backoff.delayFor(2), const Duration(seconds: 10));
    expect(backoff.delayFor(3), const Duration(seconds: 20));
    expect(backoff.delayFor(20), const Duration(minutes: 10));
  });

  test('keeps jitter within 20 percent', () {
    final backoff = BackoffPolicy(random: Random(1));
    for (var i = 0; i < 50; i++) {
      expect(backoff.delayFor(2).inMilliseconds, inInclusiveRange(8000, 12000));
    }
  });
}
