import 'api_client.dart';
import '../config/app_config.dart';

/// Cliente HTTP para APIs públicas do coldigom
class ColdigomClient extends ApiClient {
  ColdigomClient() : super(AppConfig.coldigomApiBaseUrl);
}
