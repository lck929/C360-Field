import 'package:c360/core/di/core_providers.dart';
import 'package:c360/core/mock/mock_server.dart';
import 'package:c360/core/storage/app_boxes.dart';
import 'package:c360/features/site_check/data/repositories/wifi_repository_impl.dart';
import 'package:c360/features/site_check/domain/repositories/wifi_repository.dart';
import 'package:c360/features/site_check/domain/usecases/check_site_wifi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wifiRepositoryProvider = Provider<WifiRepository>((ref) => WifiRepositoryImpl());

final checkSiteWifiProvider = Provider<CheckSiteWifi>((ref) => CheckSiteWifi(ref.watch(wifiRepositoryProvider)));

final mockServerProvider = Provider<MockServer>(
  (ref) => MockServer(
    box: AppBoxes.app,
    settings: () => ref.read(mockSettingsProvider),
    isOnline: ref.watch(connectivityProvider).isOnline,
    currentBssid: ref.watch(wifiRepositoryProvider).currentBssid,
  ),
);
