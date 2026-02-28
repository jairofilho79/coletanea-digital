import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Cliente HTTP base com tratamentos unificados de erro, retry (429) e logs.
class ApiClient {
  late final Dio _dio;
  
  /// Número máximo de retentativas em 429 (backoff com Retry-After)
  static const int maxRetries429 = 2;

  ApiClient(String baseUrl) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
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

  // Interceptors podem ser adicionados por quem herda
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    int maxRetries = 1,
  }) async {
    return _request<T>(
      () => _dio.get<T>(path, queryParameters: queryParameters, options: options),
      maxRetries: maxRetries,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int maxRetries = 0,
  }) async {
    return _request<T>(
      () => _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options),
      maxRetries: maxRetries,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int maxRetries = 0,
  }) async {
    return _request<T>(
      () => _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options),
      maxRetries: maxRetries,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int maxRetries = 0,
  }) async {
    return _request<T>(
      () => _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options),
      maxRetries: maxRetries,
    );
  }

  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() requestFunc, {
    int maxRetries = 1,
  }) async {
    int attempts = 0;
    DioException? lastError;
    bool lastWas429 = false;

    while (true) {
      try {
        return await requestFunc();
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
            statusCode == 0 ||
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

  int _parseRetryAfter(Response<dynamic>? response) {
    if (response == null) return 60;
    final v = response.headers.value('retry-after');
    if (v == null || v.isEmpty) return 60;
    final sec = int.tryParse(v);
    if (sec != null && sec > 0 && sec <= 3600) return sec;
    return 60;
  }

  Exception _handleError(DioException error, {bool lastWas429 = false}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Timeout ao conectar com o servidor');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return Exception('Não autorizado');
        }
        if (statusCode == 429 || lastWas429) {
          final retrySec = _parseRetryAfter(error.response);
          final min = (retrySec / 60).ceil();
          return Exception(
            'Muitas requisições no momento. Tente novamente em ${min > 0 ? "$min minuto(s)" : "alguns segundos"}.'
          );
        }
        if (statusCode == 0) {
          return Exception(
            'Erro de CORS: O servidor não está permitindo requisições desta origem.\n'
            'Configure CORS_ORIGINS no backend para incluir a porta do Flutter web.'
          );
        }
        return Exception('Erro na resposta do servidor: $statusCode');
      case DioExceptionType.cancel:
        return Exception('Requisição cancelada');
      default:
        final message = error.message ?? '';
        if (message.contains('CORS') || message.contains('Access-Control')) {
          return Exception(
            'Erro de CORS: Configure CORS_ORIGINS no backend.'
          );
        }
        return Exception('Erro de conexão: $message');
    }
  }
}
