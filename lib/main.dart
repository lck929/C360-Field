import 'package:c360/app.dart';
import 'package:c360/core/config/app_config.dart';
import 'package:c360/core/di/core_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initDependencies();
  runApp(
    ProviderScope(
      overrides: [configProvider.overrideWithValue(AppConfig.fromEnvironment())],
      retry: (_, _) => null,
      child: const App(),
    ),
  );
}
