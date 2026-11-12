enum WifiProblem { off, notRegistered, permissionDenied, permissionBlocked, locationOff, unreadable }

class WifiReading {
  const WifiReading({this.bssid, this.ssid, this.problem});

  final String? bssid;
  final String? ssid;
  final WifiProblem? problem;
}
