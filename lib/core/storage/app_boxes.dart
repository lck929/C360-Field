import 'package:hive_flutter/hive_flutter.dart';

abstract final class AppBoxes {
  static const _queue = 'attendance_queue';
  static const _app = 'app';

  static Future<void> open() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_queue);
    await Hive.openBox<String>(_app);
  }

  static Box<String> get queue => Hive.box<String>(_queue);

  static Box<String> get app => Hive.box<String>(_app);
}
