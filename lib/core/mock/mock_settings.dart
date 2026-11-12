class MockSettings {
  const MockSettings({
    this.faceMatches = true,
    this.registerCurrentWifi = true,
    this.noInternet = false,
    this.serverError = false,
  });

  final bool faceMatches;
  final bool registerCurrentWifi;
  final bool noInternet;
  final bool serverError;

  MockSettings copyWith({bool? faceMatches, bool? registerCurrentWifi, bool? noInternet, bool? serverError}) =>
      MockSettings(
        faceMatches: faceMatches ?? this.faceMatches,
        registerCurrentWifi: registerCurrentWifi ?? this.registerCurrentWifi,
        noInternet: noInternet ?? this.noInternet,
        serverError: serverError ?? this.serverError,
      );
}
