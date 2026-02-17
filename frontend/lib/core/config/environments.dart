/// Enum para representar os ambientes disponíveis
enum Environment {
  dev,
  prod,
}

/// Extensão para facilitar conversão de string para Environment
extension EnvironmentExtension on Environment {
  String get name {
    switch (this) {
      case Environment.dev:
        return 'dev';
      case Environment.prod:
        return 'prod';
    }
  }

  bool get isDevelopment => this == Environment.dev;
  bool get isProduction => this == Environment.prod;
}

/// Classe helper para obter o ambiente atual
class EnvironmentHelper {
  static Environment getCurrent() {
    const envString = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'dev',
    );
    
    // Converter para lowercase em runtime (não pode ser constante)
    final envLower = envString.toLowerCase();

    switch (envLower) {
      case 'prod':
      case 'production':
        return Environment.prod;
      case 'dev':
      case 'development':
      default:
        return Environment.dev;
    }
  }
}
