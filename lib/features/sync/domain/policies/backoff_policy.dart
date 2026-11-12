import 'dart:math';

class BackoffPolicy {
  BackoffPolicy({
    this.base = const Duration(seconds: 5),
    this.max = const Duration(minutes: 10),
    this.jitter = 0.2,
    Random? random,
  }) : _random = random ?? Random();

  final Duration base;
  final Duration max;
  final double jitter;
  final Random _random;

  Duration delayFor(int attempt) {
    final raw = base.inMilliseconds * pow(2, (attempt - 1).clamp(0, 30));
    final capped = min(raw, max.inMilliseconds).toDouble();
    final factor = 1 + (_random.nextDouble() * 2 - 1) * jitter;
    return Duration(milliseconds: (capped * factor).round());
  }
}
