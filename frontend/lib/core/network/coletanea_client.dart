import 'api_client.dart';
import '../config/app_config.dart';

/// Cliente HTTP para API própria da Coletânea Digital
class ColetaneaClient extends ApiClient {
  ColetaneaClient() : super(AppConfig.coletaneaApiBaseUrl) {
    // TODO: Add auth interceptor when auth is implemented
    // addInterceptor(AuthInterceptor());
  }
}
