class AppConfig {
  const AppConfig._();

  // Deployment base URL (no path). Endpoint is appended in API services.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.interiorconceptspremium.com',
  );

  static const String apiAuthToken = String.fromEnvironment(
    'API_AUTH_TOKEN',
    defaultValue: '',
  );
}
