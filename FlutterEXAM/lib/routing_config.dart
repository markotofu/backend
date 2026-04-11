class RoutingConfig {
  /// Base URL for the Valhalla server.
  ///
  /// Examples:
  /// - Android emulator: http://10.0.2.2:8002
  /// - Same-WiFi phone:  http://192.168.x.y:8002
  static const String valhallaBaseUrl = String.fromEnvironment(
    'VALHALLA_URL',
    defaultValue: 'http://10.0.2.2:8002',
  );
}
