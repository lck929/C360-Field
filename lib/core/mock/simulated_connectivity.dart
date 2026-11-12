import 'package:c360/core/network/connectivity_service.dart';

class SimulatedConnectivity implements ConnectivityService {
  SimulatedConnectivity(this._device, {required bool Function() offline}) : _offline = offline;

  final ConnectivityService _device;
  final bool Function() _offline;

  @override
  Future<bool> isOnline() async => !_offline() && await _device.isOnline();

  @override
  Stream<bool> changes() => _device.changes();
}
