import 'environments.dart';

class AppConfig {
  // Environment
  static final Environment currentEnvironment = EnvironmentHelper.getCurrent();
  static bool get isDevelopment => currentEnvironment.isDevelopment;
  static bool get isProduction => currentEnvironment.isProduction;

  // API URLs - configured via --dart-define or environment
  // Development defaults to localhost, production should be set via --dart-define
  static String get coldigomApiBaseUrl {
    const url = String.fromEnvironment(
      'COLDIGOM_API_BASE_URL',
      defaultValue: '',
    );
    if (url.isNotEmpty) return url;
    
    // Fallback baseado no ambiente
    return isDevelopment 
        ? 'http://localhost:8000'
        : 'http://129.121.44.196';
  }

  static String get coletaneaApiBaseUrl {
    const url = String.fromEnvironment(
      'COLETANEA_API_BASE_URL',
      defaultValue: '',
    );
    if (url.isNotEmpty) return url;
    
    // Fallback baseado no ambiente
    return isDevelopment 
        ? 'http://localhost:8001'
        : 'http://129.121.44.196:8001';
  }

  // App Configuration
  static const String appName = 'Coletânea Digital';
  static const String appVersion = '1.0.0';

  // Cache Configuration
  static int get maxCacheSizeMB => isDevelopment ? 500 : 1000; // Maior cache em produção
  static const Duration cacheExpirationDays = Duration(days: 30);

  // Network Configuration
  static Duration get networkTimeout => 
      isDevelopment ? const Duration(seconds: 30) : const Duration(seconds: 15);
  static const int maxRetries = 3;

  // Debug Configuration
  static bool get enableDebugLogs => isDevelopment;
}
