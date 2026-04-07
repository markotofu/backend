/// Google Sign-In configuration.
///
/// Provide the Web OAuth client ID at build/run time:
/// flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
class GoogleSignInConfig {
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static String? get webClientIdOrNull =>
      webClientId.trim().isEmpty ? null : webClientId.trim();
}
