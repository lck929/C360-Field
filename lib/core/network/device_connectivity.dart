import 'package:c360/core/network/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DeviceConnectivity implements ConnectivityService {
  final _connectivity = Connectivity();

  static bool _hasLink(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async => _hasLink(await _connectivity.checkConnectivity());

  @override
  Stream<bool> changes() => _connectivity.onConnectivityChanged.map(_hasLink).distinct();
}
