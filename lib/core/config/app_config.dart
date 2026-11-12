class AppConfig {
  const AppConfig({
    this.apiBaseUrl = '',
    this.historyDays = 14,
    this.maxSelfieBytes = 500 * 1024,
    this.appVersion = '1.0.0',
  });

  factory AppConfig.fromEnvironment() => const AppConfig(apiBaseUrl: String.fromEnvironment('API_BASE_URL'));

  final String apiBaseUrl;
  final int historyDays;
  final int maxSelfieBytes;
  final String appVersion;

  bool get useMockApi => apiBaseUrl.isEmpty;
}
