import 'package:c360/core/config/app_config.dart';
import 'package:c360/core/mock/mock_settings.dart';
import 'package:c360/core/mock/simulated_connectivity.dart';
import 'package:c360/core/network/api_client.dart';
import 'package:c360/core/network/connectivity_service.dart';
import 'package:c360/core/network/device_connectivity.dart';
import 'package:c360/core/storage/app_boxes.dart';
import 'package:c360/core/storage/hive_preferences.dart';
import 'package:c360/core/storage/preferences.dart';
import 'package:c360/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

Future<void> initDependencies() => AppBoxes.open();

final configProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final idGeneratorProvider = Provider<String Function()>((ref) => const Uuid().v4);

class MockSettingsNotifier extends Notifier<MockSettings> {
  @override
  MockSettings build() => const MockSettings();

  void update(MockSettings Function(MockSettings s) change) => state = change(state);
}

final mockSettingsProvider = NotifierProvider<MockSettingsNotifier, MockSettings>(MockSettingsNotifier.new);

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final preferencesProvider = Provider<Preferences>((ref) => HivePreferences(AppBoxes.app));

final dioProvider = Provider<Dio>(
  (ref) => buildDio(baseUrl: ref.watch(configProvider).apiBaseUrl, token: ref.watch(tokenStorageProvider).token),
);

final connectivityProvider = Provider<ConnectivityService>((ref) {
  final device = DeviceConnectivity();
  if (!ref.watch(configProvider).useMockApi) return device;
  return SimulatedConnectivity(device, offline: () => ref.read(mockSettingsProvider).noInternet);
});

final isOnlineProvider = StreamProvider<bool>((ref) async* {
  ref.watch(mockSettingsProvider.select((s) => s.noInternet));
  final connectivity = ref.watch(connectivityProvider);
  yield await connectivity.isOnline();
  yield* connectivity.changes().asyncMap((_) => connectivity.isOnline());
});

final nowProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => clock());
});
