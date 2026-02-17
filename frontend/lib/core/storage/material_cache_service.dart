import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config/app_config.dart';
import 'hive_service.dart';

/// Serviço para cache de materiais (PDF, áudio, lyrics)
class MaterialCacheService {
  static const String _materialsDirName = 'cached_materials';
  Directory? _materialsDir;
  bool _isInitialized = false;

  /// Inicializa o diretório de cache
  Future<void> init() async {
    if (_isInitialized) return;
    
    // No web, não usamos diretório de arquivos
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _materialsDir = Directory(path.join(appDir.path, _materialsDirName));
      if (!await _materialsDir!.exists()) {
        await _materialsDir!.create(recursive: true);
      }
      _isInitialized = true;
    } catch (e) {
      // Se falhar, continua sem cache de arquivos (apenas metadados no Hive)
      _isInitialized = true;
    }
  }

  /// Obtém o diretório de materiais (apenas para plataformas não-web)
  Directory? get materialsDir {
    if (kIsWeb) {
      return null; // Web não usa diretório de arquivos
    }
    if (_materialsDir == null) {
      return null;
    }
    return _materialsDir!;
  }

  /// Salva um material no cache
  Future<File?> cacheMaterial({
    required String materialId,
    required String extension,
    required List<int> data,
  }) async {
    await init();
    
    // No web, salva apenas metadados no Hive (dados podem ser armazenados como base64 se necessário)
    if (kIsWeb) {
      await HiveService.materialsBox.put(materialId, {
        'cached_at': DateTime.now().toIso8601String(),
        'size': data.length,
        'extension': extension,
        // No web, podemos armazenar como base64 se necessário, mas por enquanto apenas metadados
        'is_web': true,
      });
      return null; // Web não retorna File
    }

    if (_materialsDir == null) {
      return null;
    }

    final fileName = '$materialId.$extension';
    final file = File(path.join(_materialsDir!.path, fileName));
    await file.writeAsBytes(data);
    
    // Registra no Hive que o material está em cache
    await HiveService.materialsBox.put(materialId, {
      'path': file.path,
      'cached_at': DateTime.now().toIso8601String(),
      'size': data.length,
      'extension': extension,
      'is_web': false,
    });

    return file;
  }

  /// Obtém um material do cache
  File? getCachedMaterial(String materialId) {
    if (kIsWeb) {
      // No web, não retorna File (usa URLs diretas)
      return null;
    }

    final cacheInfo = HiveService.materialsBox.get(materialId);
    if (cacheInfo == null) {
      return null;
    }

    final filePath = (cacheInfo as Map)['path'] as String?;
    if (filePath == null) {
      return null;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      // Arquivo foi removido mas ainda está no Hive
      HiveService.materialsBox.delete(materialId);
      return null;
    }

    return file;
  }

  /// Verifica se um material está em cache
  bool isMaterialCached(String materialId) {
    if (kIsWeb) {
      // No web, verifica apenas se está registrado no Hive
      return HiveService.materialsBox.get(materialId) != null;
    }
    return getCachedMaterial(materialId) != null;
  }

  /// Remove um material do cache
  Future<void> removeMaterial(String materialId) async {
    if (!kIsWeb) {
      final file = getCachedMaterial(materialId);
      if (file != null) {
        await file.delete();
      }
    }
    await HiveService.materialsBox.delete(materialId);
  }

  /// Obtém o tamanho total do cache em bytes
  Future<int> getCacheSize() async {
    await init();
    
    if (kIsWeb) {
      // No web, calcula tamanho baseado nos metadados do Hive
      int totalSize = 0;
      for (final key in HiveService.materialsBox.keys) {
        final cacheInfo = HiveService.materialsBox.get(key);
        if (cacheInfo != null) {
          final size = (cacheInfo as Map)['size'] as int?;
          if (size != null) {
            totalSize += size;
          }
        }
      }
      return totalSize;
    }

    if (_materialsDir == null) {
      return 0;
    }

    int totalSize = 0;
    if (await _materialsDir!.exists()) {
      await for (final entity in _materialsDir!.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }

    return totalSize;
  }

  /// Obtém o tamanho do cache em MB
  Future<double> getCacheSizeMB() async {
    final sizeBytes = await getCacheSize();
    return sizeBytes / (1024 * 1024);
  }

  /// Limpa todo o cache de materiais
  Future<void> clearAllMaterials() async {
    await init();
    
    if (!kIsWeb && _materialsDir != null) {
      // Remove arquivos (apenas em plataformas não-web)
      if (await _materialsDir!.exists()) {
        await for (final entity in _materialsDir!.list(recursive: true)) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    }

    // Limpa Hive (sempre)
    await HiveService.materialsBox.clear();
  }

  /// Remove materiais antigos (mais de X dias)
  Future<void> removeOldMaterials({int days = 30}) async {
    await init();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final keysToRemove = <String>[];

    for (final key in HiveService.materialsBox.keys) {
      final cacheInfo = HiveService.materialsBox.get(key);
      if (cacheInfo != null) {
        final cachedAt = (cacheInfo as Map)['cached_at'] as String?;
        if (cachedAt != null) {
          try {
            final cachedDate = DateTime.parse(cachedAt);
            if (cachedDate.isBefore(cutoffDate)) {
              keysToRemove.add(key.toString());
            }
          } catch (e) {
            // Data inválida, remove
            keysToRemove.add(key.toString());
          }
        }
      }
    }

    for (final key in keysToRemove) {
      await removeMaterial(key);
    }
  }

  /// Verifica se há espaço suficiente no cache
  Future<bool> hasSpaceFor(int sizeBytes) async {
    final currentSize = await getCacheSize();
    final maxSizeBytes = AppConfig.maxCacheSizeMB * 1024 * 1024;
    return (currentSize + sizeBytes) <= maxSizeBytes;
  }

  /// Obtém lista de materiais em cache
  List<String> getCachedMaterialIds() {
    return HiveService.materialsBox.keys.map((key) => key.toString()).toList();
  }
}
