import 'package:c360/core/di/core_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockServerPanel extends ConsumerWidget {
  const MockServerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(mockSettingsProvider);
    final notifier = ref.read(mockSettingsProvider.notifier);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Face matches'),
            subtitle: const Text('Off returns FACE_NOT_MATCHED'),
            value: settings.faceMatches,
            onChanged: (v) => notifier.update((s) => s.copyWith(faceMatches: v)),
          ),
          SwitchListTile(
            title: const Text('Register current Wi-Fi'),
            subtitle: const Text('Treat the Wi-Fi this phone is on as site Wi-Fi'),
            value: settings.registerCurrentWifi,
            onChanged: (v) => notifier.update((s) => s.copyWith(registerCurrentWifi: v)),
          ),
          SwitchListTile(
            title: const Text('Simulate no internet'),
            subtitle: const Text('Stay on Wi-Fi but drop the connection to the server'),
            value: settings.noInternet,
            onChanged: (v) => notifier.update((s) => s.copyWith(noInternet: v)),
          ),
          SwitchListTile(
            title: const Text('Simulate server error'),
            subtitle: const Text('Return 503 to show retry with backoff'),
            value: settings.serverError,
            onChanged: (v) => notifier.update((s) => s.copyWith(serverError: v)),
          ),
        ],
      ),
    );
  }
}
