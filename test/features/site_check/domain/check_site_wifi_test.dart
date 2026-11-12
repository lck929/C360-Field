import 'package:c360/core/utils/bssid.dart';
import 'package:c360/features/site_check/domain/entities/wifi_reading.dart';
import 'package:c360/features/site_check/domain/repositories/wifi_repository.dart';
import 'package:c360/features/site_check/domain/usecases/check_site_wifi.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWifi implements WifiRepository {
  _FakeWifi(this.reading);

  final WifiReading reading;

  @override
  Future<WifiReading> read() async => reading;

  @override
  Future<String?> currentBssid() async => reading.bssid;
}

void main() {
  const registered = ['3c:84:6a:1f:22:b0', '3c:84:6a:1f:22:b1'];

  test('normalises case, separators and dropped leading zeros', () {
    expect(normalizeBssid('3C-84-6A-1F-22-B0'), '3c:84:6a:1f:22:b0');
    expect(normalizeBssid('a:4:6a:1f:2:b0'), '0a:04:6a:1f:02:b0');
  });

  test('passes on a registered access point', () async {
    final result = await CheckSiteWifi(_FakeWifi(const WifiReading(bssid: '3C:84:6A:1F:22:B1')))(registered);

    expect(result.passed, isTrue);
  });

  test('fails on an unregistered access point', () async {
    final result = await CheckSiteWifi(_FakeWifi(const WifiReading(bssid: 'aa:bb:cc:dd:ee:ff', ssid: 'Cafe')))(
      registered,
    );

    expect(result.problem, WifiProblem.notRegistered);
    expect(result.reading.ssid, 'Cafe');
  });

  test('passes device problems through', () {
    expect(
      evaluateSiteWifi(const WifiReading(problem: WifiProblem.permissionDenied), registered),
      WifiProblem.permissionDenied,
    );
    expect(evaluateSiteWifi(const WifiReading(), registered), WifiProblem.unreadable);
  });
}
