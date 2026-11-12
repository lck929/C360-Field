import 'package:c360/features/site_check/domain/entities/wifi_reading.dart';

class SiteCheckResult {
  const SiteCheckResult({required this.reading, this.problem});

  final WifiReading reading;
  final WifiProblem? problem;

  bool get passed => problem == null;
}
