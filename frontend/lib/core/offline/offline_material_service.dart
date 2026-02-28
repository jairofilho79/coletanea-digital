import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/material_cache_service.dart';
import 'offline_download_progress.dart';

/// Item de material para download (parseado do batch)
class _BatchMaterialItem {
  final String id;
  final String path;
  final String materialKindId;
  final String materialKindName;
  final String materialTypeName;

  _BatchMaterialItem({
    required this.id,
    required this.path,
    required this.materialKindId,
    required this.materialKindName,
    required this.materialTypeName,
  });
}

/// Serviço de download em lote por material kind (GET /batch + downloads)
class OfflineMaterialService {
  static const int maxConcurrent = 3;
  static const int maxRetries = 3;
  static const int estimatedMaxFileBytes = 20 * 1024 * 1024; // 20 MB

  final MaterialCacheService _cache;
  final Dio _dio;

  OfflineMaterialService({
    MaterialCacheService? cache,
    Dio? dio,
  })  : _cache = cache ?? MaterialCacheService(),
        _dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConfig.coldigomApiBaseUrl,
          connectTimeout: AppConfig.networkTimeout,
          receiveTimeout: const Duration(minutes: 2),
        ));

  /// Baixa todos os materiais de um material kind (PDF, áudio, texto)
  Future<OfflineDownloadResult> downloadByMaterialKind(
    String materialKindId,
    String materialKindName, {
    void Function(OfflineDownloadProgress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final errors = <String>[];
    int completed = 0;
    int failed = 0;
    int skipped = 0;

    final list = await _fetchBatchList(
      materialKindId,
      materialKindName,
      cancelToken: cancelToken,
    );
    if (list.isEmpty) {
      onProgress?.call(OfflineDownloadProgress(
        completed: 0,
        total: 0,
        message: 'Nenhum material encontrado para este tipo.',
      ));
      return OfflineDownloadResult(
        completed: 0,
        failed: 0,
        skipped: 0,
        total: 0,
      );
    }

    final toDownload = <_BatchMaterialItem>[];
    for (final item in list) {
      if (cancelToken?.isCancelled == true) break;
      if (_cache.isMaterialCached(item.id) || _cache.isMaterialTextCached(item.id)) {
        skipped++;
        continue;
      }
      toDownload.add(item);
    }

    final total = toDownload.length + skipped;
    void report() {
      onProgress?.call(OfflineDownloadProgress(
        completed: completed,
        total: total,
        failed: failed,
        skipped: skipped,
        message: 'Baixando ${completed + failed + 1} de $total...',
      ));
    }

    for (var i = 0; i < toDownload.length; i += maxConcurrent) {
      if (cancelToken?.isCancelled == true) break;
      final chunk = toDownload.skip(i).take(maxConcurrent).toList();
      final results = await Future.wait(
        chunk.map((item) => _downloadOne(
          item,
          materialKindId,
          materialKindName,
          cancelToken: cancelToken,
        )),
      );
      for (var j = 0; j < results.length; j++) {
        if (results[j] == true) completed++;
        else {
          failed++;
          errors.add('Material ${chunk[j].id}');
        }
      }
      report();
    }

    onProgress?.call(OfflineDownloadProgress(
      completed: completed,
      total: total,
      failed: failed,
      skipped: skipped,
      message: null,
    ));

    return OfflineDownloadResult(
      completed: completed,
      failed: failed,
      skipped: skipped,
      total: total,
      errors: errors,
    );
  }

  Future<List<_BatchMaterialItem>> _fetchBatchList(
    String materialKindId,
    String materialKindName, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/praise-materials/batch',
      queryParameters: {
        'material_kind_ids': materialKindId,
        'operation': 'union',
        'is_old': 'false',
      },
      options: Options(
        receiveTimeout: AppConfig.networkTimeout,
        sendTimeout: AppConfig.networkTimeout,
      ),
      cancelToken: cancelToken,
    );

    if (response.data == null) return [];
    final list = <_BatchMaterialItem>[];
    for (final raw in response.data!) {
      if (raw is! Map<String, dynamic>) continue;
      final materialKind = raw['material_kind'] as Map?;
      final materialType = raw['material_type'] as Map?;
      final typeNameStr = materialType != null
          ? (materialType['name'] as String?)?.toLowerCase() ?? ''
          : '';
      if (typeNameStr.contains('youtube')) continue;
      final kindName = materialKind != null
          ? ((materialKind['name'] as String?) ?? materialKindName)
          : materialKindName;
      final path = raw['path'];
      final pathStr = path is String ? path : path?.toString() ?? '';
      list.add(_BatchMaterialItem(
        id: raw['id'] as String? ?? '',
        path: pathStr,
        materialKindId: raw['material_kind_id'] as String? ?? materialKindId,
        materialKindName: kindName,
        materialTypeName: typeNameStr,
      ));
    }
    return list;
  }

  /// Retorna true se salvou, false se falhou (após retries)
  Future<bool> _downloadOne(
    _BatchMaterialItem item,
    String materialKindId,
    String materialKindName, {
    CancelToken? cancelToken,
  }) async {
    final isText = _isTextType(item.materialTypeName, item.path);
    if (isText) {
      return _downloadText(item, materialKindId, materialKindName, cancelToken: cancelToken);
    }
    return _downloadFile(item, materialKindId, materialKindName, cancelToken: cancelToken);
  }

  bool _isTextType(String typeName, String path) {
    if (typeName.contains('text') || typeName.contains('lyric')) return true;
    if (path.length > 100 &&
        !path.contains('.pdf') &&
        !path.contains('.mp3') &&
        !path.contains('/') &&
        !path.contains('http')) return true;
    return false;
  }

  String _extensionForType(String typeName, String path) {
    if (typeName.contains('pdf')) return 'pdf';
    if (typeName.contains('audio') || path.endsWith('.mp3') || path.endsWith('.m4a')) return 'mp3';
    return 'pdf';
  }

  Future<bool> _downloadFile(
    _BatchMaterialItem item,
    String materialKindId,
    String materialKindName, {
    CancelToken? cancelToken,
  }) async {
    if (!await _cache.hasSpaceFor(estimatedMaxFileBytes)) return false;
    final path = '/api/v1/praise-materials/${item.id}/download';
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      if (cancelToken?.isCancelled == true) return false;
      try {
        await Future.delayed(Duration(milliseconds: attempt == 0 ? 0 : (1 << attempt) * 500));
        final response = await _dio.get<List<int>>(
          path,
          options: Options(responseType: ResponseType.bytes),
          cancelToken: cancelToken,
        );
        if (response.data == null || response.data!.isEmpty) return false;
        final ext = _extensionForType(item.materialTypeName, item.path);
        await _cache.cacheMaterial(
          materialId: item.id,
          extension: ext,
          data: response.data!,
          materialKindId: materialKindId,
          materialKindName: materialKindName,
        );
        return true;
      } catch (_) {
        if (attempt == maxRetries - 1) return false;
      }
    }
    return false;
  }

  Future<bool> _downloadText(
    _BatchMaterialItem item,
    String materialKindId,
    String materialKindName, {
    CancelToken? cancelToken,
  }) async {
    final path = '/api/v1/praise-materials/${item.id}';
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      if (cancelToken?.isCancelled == true) return false;
      try {
        await Future.delayed(Duration(milliseconds: attempt == 0 ? 0 : (1 << attempt) * 500));
        final response = await _dio.get<Map<String, dynamic>>(
          path,
          cancelToken: cancelToken,
        );
        final content = response.data?['path'] as String? ?? '';
        if (content.isEmpty && item.path.length > 50) {
          await _cache.cacheMaterialText(
            item.id,
            item.path,
            materialKindId: materialKindId,
            materialKindName: materialKindName,
          );
        } else if (content.isNotEmpty) {
          await _cache.cacheMaterialText(
            item.id,
            content,
            materialKindId: materialKindId,
            materialKindName: materialKindName,
          );
        }
        return true;
      } catch (_) {
        if (attempt == maxRetries - 1) return false;
      }
    }
    return false;
  }
}
