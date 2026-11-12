import 'package:c360/features/site_check/domain/entities/wifi_reading.dart';

String wifiMessage(WifiProblem problem, {String? ssid, required String projectName}) => switch (problem) {
      WifiProblem.notRegistered => ssid == null
          ? 'This Wi-Fi network isn’t registered for $projectName. Join the site Wi-Fi.'
          : 'Connected to “$ssid”, which isn’t registered for $projectName. Join the site Wi-Fi.',
      WifiProblem.off => 'Wi-Fi is off or not connected. Turn it on and join the site network.',
      WifiProblem.permissionDenied => 'Allow location access so the app can read which Wi-Fi network you’re on.',
      WifiProblem.permissionBlocked =>
        'Location access is off for C360 Field. Allow it in Settings so the app can read the site Wi-Fi.',
      WifiProblem.locationOff => 'Turn on Location. Android needs it to read the Wi-Fi network.',
      WifiProblem.unreadable => 'Couldn’t read the Wi-Fi network. Reconnect to the site Wi-Fi and try again.',
    };
