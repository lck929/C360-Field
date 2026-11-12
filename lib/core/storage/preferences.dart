abstract interface class Preferences {
  Future<String?> get(String key);

  Future<void> put(String key, String value);
}
