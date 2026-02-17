import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Cliente HTTP para APIs públicas do coldigom (apenas GET)
class ColdigomClient {
  late final Dio _dio;

  ColdigomClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.coldigomApiBaseUrl,
        connectTimeout: AppConfig.networkTimeout,
        receiveTimeout: AppConfig.networkTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging (in debug mode)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// GET request to coldigom API
  /// Com retry limitado para evitar loops infinitos
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    int maxRetries = 1, // Máximo 1 retry para evitar loops
  }) async {
    int attempts = 0;
    DioException? lastError;
    
    while (attempts <= maxRetries) {
      try {
        return await _dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
        );
      } on DioException catch (e) {
        lastError = e;
        attempts++;

        final statusCode = e.response?.statusCode;

        // Não retry em 429 (rate limit) — nova tentativa só piora
        if (statusCode == 429) {
          break;
        }

        // Não retry em erros de CORS ou conexão
        if (e.type == DioExceptionType.connectionError ||
            e.response?.statusCode == 0 ||
            (e.message?.toLowerCase().contains('cors') ?? false)) {
          break;
        }

        // Se ainda há tentativas, aguarda antes de retry
        if (attempts <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        }
      }
    }
    
    // Se chegou aqui, todas as tentativas falharam
    throw _handleError(lastError!);
  }

  /// Handle Dio errors
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Timeout ao conectar com o servidor');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 429) {
          return Exception(
            'Muitas requisições. Aguarde um momento antes de tentar novamente.'
          );
        }
        if (statusCode == 0) {
          // Status 0 geralmente indica erro de CORS
          return Exception(
            'Erro de CORS: O coldigom não está permitindo requisições desta origem.\n'
            'Configure CORS_ORIGINS no coldigom para incluir a porta do Flutter web.\n'
            'Consulte docs/CORS_SETUP.md para mais informações.'
          );
        }
        return Exception('Erro na resposta do servidor: $statusCode');
      case DioExceptionType.cancel:
        return Exception('Requisição cancelada');
      default:
        // Verifica se é erro de CORS pela mensagem
        final message = error.message ?? '';
        if (message.contains('CORS') || message.contains('Access-Control')) {
          return Exception(
            'Erro de CORS: Configure CORS_ORIGINS no coldigom.\n'
            'Consulte docs/CORS_SETUP.md para mais informações.'
          );
        }
        return Exception('Erro de conexão: $message');
    }
  }
}
