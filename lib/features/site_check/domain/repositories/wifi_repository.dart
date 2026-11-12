import 'package:c360/features/site_check/domain/entities/wifi_reading.dart';

abstract interface class WifiRepository {
  Future<WifiReading> read();

  Future<String?> currentBssid();
}
