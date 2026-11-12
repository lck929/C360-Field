import 'package:c360/core/utils/bssid.dart';
import 'package:c360/features/site_check/domain/entities/site_check_result.dart';
import 'package:c360/features/site_check/domain/entities/wifi_reading.dart';
import 'package:c360/features/site_check/domain/repositories/wifi_repository.dart';

WifiProblem? evaluateSiteWifi(WifiReading reading, Iterable<String> registered) {
  if (reading.problem != null) return reading.problem;
  final bssid = reading.bssid;
  if (bssid == null) return WifiProblem.unreadable;
  return registered.map(normalizeBssid).contains(normalizeBssid(bssid)) ? null : WifiProblem.notRegistered;
}

class CheckSiteWifi {
  const CheckSiteWifi(this._repository);

  final WifiRepository _repository;

  Future<SiteCheckResult> call(List<String> registeredBssids) async {
    final reading = await _repository.read();
    return SiteCheckResult(reading: reading, problem: evaluateSiteWifi(reading, registeredBssids));
  }
}
