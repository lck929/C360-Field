import 'dart:io';

import 'package:c360/core/utils/bssid.dart';
import 'package:c360/features/site_check/domain/entities/wifi_reading.dart';
import 'package:c360/features/site_check/domain/repositories/wifi_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiRepositoryImpl implements WifiRepository {
  final _info = NetworkInfo();

  @override
  Future<WifiReading> read() async {
    final links = await Connectivity().checkConnectivity();
    if (!links.contains(ConnectivityResult.wifi)) return const WifiReading(problem: WifiProblem.off);

    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted && !status.isLimited && !status.isPermanentlyDenied && !status.isRestricted) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return const WifiReading(problem: WifiProblem.permissionBlocked);
    }
    if (!status.isGranted && !status.isLimited) return const WifiReading(problem: WifiProblem.permissionDenied);

    if (Platform.isAndroid && await Permission.locationWhenInUse.serviceStatus != ServiceStatus.enabled) {
      return const WifiReading(problem: WifiProblem.locationOff);
    }

    final bssid = await _bssid();
    if (bssid == null) return const WifiReading(problem: WifiProblem.unreadable);
    return WifiReading(bssid: bssid, ssid: await _ssid());
  }

  @override
  Future<String?> currentBssid() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted || status.isLimited ? _bssid() : null;
  }

  Future<String?> _bssid() async {
    try {
      final raw = await _info.getWifiBSSID();
      if (raw == null || raw.isEmpty || raw == '02:00:00:00:00:00') return null;
      return normalizeBssid(raw);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _ssid() async {
    try {
      final ssid = (await _info.getWifiName())?.replaceAll('"', '').trim();
      return ssid == null || ssid.isEmpty || ssid == '<unknown ssid>' ? null : ssid;
    } catch (_) {
      return null;
    }
  }
}
