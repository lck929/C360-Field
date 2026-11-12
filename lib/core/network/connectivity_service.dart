abstract interface class ConnectivityService {
  Future<bool> isOnline();

  Stream<bool> changes();
}
