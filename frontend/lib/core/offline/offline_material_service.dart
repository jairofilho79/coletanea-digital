import 'dart:async';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
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
  static const int maxConcurrent = 1;
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
    int textsCompleted = 0;
    int textsFailed = 0;

    final list = await _fetchBatchList(
      materialKindId,
      materialKindName,
      cancelToken: cancelToken,
    );
    if (list.isEmpty) {
      onProgress?.call(const OfflineDownloadProgress(
        completed: 0,
        total: 0,
        message: 'Nenhum material encontrado para este tipo.',
      ));
      return const OfflineDownloadResult(
        completed: 0,
        failed: 0,
        skipped: 0,
        total: 0,
      );
    }

    final toDownloadTexts = <_BatchMaterialItem>[];
    final toDownloadFiles = <_BatchMaterialItem>[];

    for (final item in list) {
      if (cancelToken?.isCancelled == true) break;
      if (_cache.isMaterialCached(item.id) || _cache.isMaterialTextCached(item.id)) {
        skipped++;
        continue;
      }
      if (_isTextType(item.materialTypeName, item.path)) {
        toDownloadTexts.add(item);
      } else {
        toDownloadFiles.add(item);
      }
    }

    final totalTexts = toDownloadTexts.length;
    final totalFiles = toDownloadFiles.length;
    final totalToProcess = totalTexts + totalFiles;

    void reportProgress() {
      onProgress?.call(OfflineDownloadProgress(
        completed: textsCompleted,
        total: totalToProcess + skipped,
        failed: textsFailed,
        skipped: skipped,
        message: 'Baixando textos ${textsCompleted + textsFailed + 1} de $totalTexts...',
      ));
    }

    // Baixa os textos primeiramente (são requisições JSON bem leves)
    for (var i = 0; i < totalTexts; i += maxConcurrent) {
      if (cancelToken?.isCancelled == true) break;
      final chunk = toDownloadTexts.skip(i).take(maxConcurrent).toList();
      final results = await Future.wait(
        chunk.map((item) => _downloadText(
              item,
              materialKindId,
              materialKindName,
              cancelToken: cancelToken,
            )),
      );
      for (var j = 0; j < results.length; j++) {
        if (results[j] == true) {
          textsCompleted++;
        } else {
          textsFailed++;
          errors.add('Material de texto ${chunk[j].id} falhou.');
        }
      }
      reportProgress();
    }

    completed += textsCompleted;
    failed += textsFailed;

    // Baixa os arquivos pesados via ZIP se houver
    if (totalFiles > 0 && cancelToken?.isCancelled != true) {
      if (!await _cache.hasSpaceFor(estimatedMaxFileBytes * totalFiles)) {
         errors.add('Espaço insuficiente para baixar $totalFiles arquivos.');
         failed += totalFiles;
      } else {
        try {
          final path = '/api/v1/praises/download-by-material-kind';
          final response = await _dio.get<List<int>>(
            path,
            queryParameters: {'material_kind_id': materialKindId},
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(minutes: 5),
            ),
            cancelToken: cancelToken,
            onReceiveProgress: (count, total) {
              int reportedTotal = total;
              if (reportedTotal == -1) reportedTotal = totalFiles * estimatedMaxFileBytes; // estimativa longa
              onProgress?.call(OfflineDownloadProgress(
                completed: textsCompleted,
                total: totalToProcess + skipped,
                failed: textsFailed,
                skipped: skipped,
                bytesDownloaded: count,
                message: 'Baixando master ZIP de mídias... ${(count / 1024 / 1024).toStringAsFixed(1)} MB',
              ));
            },
          );

          final bytes = response.data;
          if (bytes != null && bytes.isNotEmpty) {
            onProgress?.call(OfflineDownloadProgress(
              completed: textsCompleted,
              total: totalToProcess + skipped,
              failed: textsFailed,
              skipped: skipped,
              bytesDownloaded: bytes.length,
              message: 'Descompactando mídias extraídas internamente (Isolate)...',
            ));

            // Movemos a extração das pastas ZIP e SUB-ZIP para uma Thread Separada (Isolate)
            final extractedFiles = await Isolate.run(() {
              final archive = ZipDecoder().decodeBytes(bytes);
              final result = <String, List<int>>{};
              
              for (final file in archive) {
                // Arquivos zipados divididos em chunk part_xxx.zip virão do backend.
                if (file.isFile && file.name.endsWith('.zip')) {
                  final innerArchive = ZipDecoder().decodeBytes(file.content as List<int>);
                  for (final innerFile in innerArchive) {
                    if (innerFile.isFile) {
                      result[innerFile.name] = innerFile.content as List<int>;
                    }
                  }
                }
              }
              return result;
            });

            // Salvando arquivos extraídos na Hive/Storage
            int filesExtracted = 0;
            for (final entry in extractedFiles.entries) {
              final parts = entry.key.split('/');
              if (parts.isEmpty) continue;
              
              final fileName = parts.last;
              final dotIndex = fileName.lastIndexOf('.');
              if (dotIndex == -1) continue;

              final materialId = fileName.substring(0, dotIndex);
              final ext = fileName.substring(dotIndex + 1);

              await _cache.cacheMaterial(
                materialId: materialId,
                extension: ext,
                data: entry.value,
                materialKindId: materialKindId,
                materialKindName: materialKindName,
              );
              filesExtracted++;
            }

            completed += filesExtracted;
            if (filesExtracted < totalFiles) {
              failed += totalFiles - filesExtracted;
              errors.add('Apenas $filesExtracted de $totalFiles mídias foram encontradas no ZIP.');
            }
          } else {
            failed += totalFiles;
            errors.add('Nenhum dado recebido do ZIP.');
          }
        } catch (e) {
          failed += totalFiles;
          errors.add('Erro na conversão/download do ZIP: $e');
        }
      }
    }

    onProgress?.call(OfflineDownloadProgress(
      completed: completed,
      total: totalToProcess + skipped,
      failed: failed,
      skipped: skipped,
      message: null,
    ));

    return OfflineDownloadResult(
      completed: completed,
      failed: failed,
      skipped: skipped,
      total: totalToProcess + skipped,
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
        await Future.delayed(Duration(milliseconds: attempt == 0 ? 150 : (1 << attempt) * 500));
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
      } on DioException catch (e) {
        if (e.response?.statusCode == 429) {
          final retryAfterStr = e.response?.headers.value('retry-after');
          final sec = int.tryParse(retryAfterStr ?? '60') ?? 60;
          await Future.delayed(Duration(seconds: sec));
          if (attempt < maxRetries - 1) continue;
        }
        if (attempt == maxRetries - 1) return false;
      } catch (_) {
        if (attempt == maxRetries - 1) return false;
      }
    }
    return false;
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
}
