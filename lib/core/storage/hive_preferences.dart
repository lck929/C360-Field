import 'package:c360/core/storage/preferences.dart';
import 'package:hive/hive.dart';

class HivePreferences implements Preferences {
  HivePreferences(this._box);

  final Box<String> _box;

  @override
  Future<String?> get(String key) async => _box.get('pref:$key');

  @override
  Future<void> put(String key, String value) => _box.put('pref:$key', value);
}
