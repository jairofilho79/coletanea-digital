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

  /// Número máximo de retentativas em 429 (backoff com Retry-After)
  static const int maxRetries429 = 2;

  /// GET request to coldigom API
  /// Em 429: usa header Retry-After, senão backoff exponencial; retenta até [maxRetries429] vezes.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    int maxRetries = 1, // Para erros que não são 429
  }) async {
    int attempts = 0;
    DioException? lastError;
    bool lastWas429 = false;

    while (true) {
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

        if (statusCode == 429) {
          lastWas429 = true;
          // Retry com backoff: usar Retry-After se vier no header, senão 60s
          if (attempts <= maxRetries429) {
            final retryAfterSeconds = _parseRetryAfter(e.response);
            await Future.delayed(Duration(seconds: retryAfterSeconds));
            continue;
          }
          break;
        }

        // Não retry em erros de CORS ou conexão
        if (e.type == DioExceptionType.connectionError ||
            e.response?.statusCode == 0 ||
            (e.message?.toLowerCase().contains('cors') ?? false)) {
          break;
        }

        // Para outros erros: retry limitado
        if (attempts > maxRetries) break;
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }

    throw _handleError(lastError!, lastWas429: lastWas429);
  }

  /// Lê Retry-After do header (segundos). Se ausente ou inválido, retorna 60.
  int _parseRetryAfter(Response<dynamic>? response) {
    if (response == null) return 60;
    final v = response.headers.value('retry-after');
    if (v == null || v.isEmpty) return 60;
    final sec = int.tryParse(v);
    if (sec != null && sec > 0 && sec <= 3600) return sec;
    return 60;
  }

  /// Handle Dio errors. [lastWas429] indica que o último erro foi 429 (após retentativas).
  Exception _handleError(DioException error, {bool lastWas429 = false}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Timeout ao conectar com o servidor');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 429 || lastWas429) {
          final retrySec = _parseRetryAfter(error.response);
          final min = (retrySec / 60).ceil();
          return Exception(
            'Muitas requisições no momento. Tente novamente em ${min > 0 ? "$min minuto(s)" : "alguns segundos"}.'
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
