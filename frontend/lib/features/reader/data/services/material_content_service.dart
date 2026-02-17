import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/storage/material_cache_service.dart';

/// Serviço para buscar conteúdo de materiais de texto do cache ou API
class MaterialContentService {
  final MaterialCacheService _cacheService;
  final Dio _dio;

  MaterialContentService({
    MaterialCacheService? cacheService,
    Dio? dio,
  })  : _cacheService = cacheService ?? MaterialCacheService(),
        _dio = dio ?? Dio();

  /// Verifica se o path parece ser texto direto (não URL/arquivo)
  bool _isDirectText(String path) {
    // Textos geralmente são longos, não têm extensão de arquivo comum, e não contêm "/" ou "http"
    return path.length > 50 &&
        !path.contains('.pdf') &&
        !path.contains('.mp3') &&
        !path.contains('http://') &&
        !path.contains('https://') &&
        !path.contains('/') &&
        !path.contains('\\');
  }

  /// Busca conteúdo do material do cache ou API
  Future<String> getMaterialContent(String materialId, String materialPath) async {
    // 1. Verificar cache primeiro
    final cachedContent = _cacheService.getCachedMaterialText(materialId);
    if (cachedContent != null) {
      return cachedContent;
    }

    // 2. Se o path parece ser texto direto, usar diretamente
    if (_isDirectText(materialPath)) {
      await _cacheService.cacheMaterialText(materialId, materialPath);
      return materialPath;
    }

    // 3. Buscar da API do coldigom
    try {
      final baseUrl = AppConfig.coldigomApiBaseUrl;
      final url = '$baseUrl/api/v1/praise-materials/$materialId';

      final response = await _dio.get(
        url,
        options: Options(
          receiveTimeout: AppConfig.networkTimeout,
          sendTimeout: AppConfig.networkTimeout,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final materialData = response.data as Map<String, dynamic>;
        final content = materialData['path'] as String? ?? '';

        // Cachear conteúdo
        if (content.isNotEmpty) {
          await _cacheService.cacheMaterialText(materialId, content);
        }

        return content;
      } else {
        throw Exception('Resposta inválida da API: ${response.statusCode}');
      }
    } catch (e) {
      // Se falhar, tentar usar materialPath como fallback
      if (materialPath.isNotEmpty) {
        await _cacheService.cacheMaterialText(materialId, materialPath);
        return materialPath;
      }
      rethrow;
    }
  }
}
