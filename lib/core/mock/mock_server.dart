import 'package:c360/core/error/app_exception.dart';
import 'package:c360/core/mock/mock_settings.dart';
import 'package:c360/core/network/api_client.dart';
import 'package:c360/core/utils/bssid.dart';
import 'package:hive/hive.dart';

class MockServer {
  MockServer({
    required this.box,
    required MockSettings Function() settings,
    required Future<bool> Function() isOnline,
    required Future<String?> Function() currentBssid,
  })  : _settings = settings,
        _isOnline = isOnline,
        _currentBssid = currentBssid;

  static const siteBssids = ['3c:84:6a:1f:22:b0', '3c:84:6a:1f:22:b1'];

  final Box<String> box;
  final MockSettings Function() _settings;
  final Future<bool> Function() _isOnline;
  final Future<String?> Function() _currentBssid;

  MockSettings get settings => _settings();

  Future<void> reach() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!await _isOnline()) throw const AppException.network();
    if (settings.serverError) throw httpFailure(503, 'Service temporarily unavailable');
  }

  Future<List<String>> registeredBssids() async {
    final current = settings.registerCurrentWifi ? await _currentBssid() : null;
    return [...siteBssids, if (current != null) normalizeBssid(current)];
  }
}
