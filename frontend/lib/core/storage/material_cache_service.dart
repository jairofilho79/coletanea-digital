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
    String? materialKindId,
    String? materialKindName,
  }) async {
    await init();

    final meta = <String, dynamic>{
      'cached_at': DateTime.now().toIso8601String(),
      'size': data.length,
      'extension': extension,
    };
    if (materialKindId != null) meta['material_kind_id'] = materialKindId;
    if (materialKindName != null) meta['material_kind_name'] = materialKindName;

    // No web, salva apenas metadados no Hive (dados podem ser armazenados como base64 se necessário)
    if (kIsWeb) {
      meta['is_web'] = true;
      await HiveService.materialsBox.put(materialId, meta);
      return null; // Web não retorna File
    }

    if (_materialsDir == null) {
      return null;
    }

    final fileName = '$materialId.$extension';
    final file = File(path.join(_materialsDir!.path, fileName));
    await file.writeAsBytes(data);

    meta['path'] = file.path;
    meta['is_web'] = false;
    await HiveService.materialsBox.put(materialId, meta);

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
      int totalSize = 0;
      for (final key in HiveService.materialsBox.keys) {
        final cacheInfo = HiveService.materialsBox.get(key);
        if (cacheInfo == null) continue;
        final m = cacheInfo as Map;
        final size = m['size'] as int?;
        if (size != null) {
          totalSize += size;
        } else {
          final content = m['content'] as String?;
          if (content != null) totalSize += content.length;
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

  /// Obtém lista de materiais em cache (apenas IDs de arquivo, não texto)
  List<String> getCachedMaterialIds() {
    return HiveService.materialsBox.keys
        .map((key) => key.toString())
        .where((k) => !k.startsWith('material_text_'))
        .toList();
  }

  /// Obtém IDs de material kind que têm pelo menos um material em cache
  List<String> getCachedMaterialKindIds() {
    final kindIds = <String>{};
    for (final key in HiveService.materialsBox.keys) {
      final k = key.toString();
      if (k.startsWith('material_text_')) {
        final info = HiveService.materialsBox.get(key);
        if (info != null) {
          final kid = (info as Map)['material_kind_id'] as String?;
          if (kid != null && kid.isNotEmpty) kindIds.add(kid);
        }
        continue;
      }
      final info = HiveService.materialsBox.get(key);
      if (info != null) {
        final kid = (info as Map)['material_kind_id'] as String?;
        if (kid != null && kid.isNotEmpty) kindIds.add(kid);
      }
    }
    return kindIds.toList();
  }

  /// Metadados de um material em cache (para listagem por kind)
  Map<String, dynamic>? getCachedMaterialMeta(String materialId) {
    final info = HiveService.materialsBox.get(materialId);
    if (info == null) return null;
    final m = info as Map;
    return {
      'material_id': materialId,
      'size': m['size'] as int? ?? 0,
      'extension': m['extension'] as String?,
      'material_kind_id': m['material_kind_id'] as String?,
      'material_kind_name': m['material_kind_name'] as String?,
      'cached_at': m['cached_at'] as String?,
    };
  }

  /// Obtém materiais em cache de um material kind (arquivos + textos)
  List<Map<String, dynamic>> getCachedMaterialsByKind(String materialKindId) {
    final list = <Map<String, dynamic>>[];
    for (final key in HiveService.materialsBox.keys) {
      final k = key.toString();
      if (k.startsWith('material_text_')) {
        final info = HiveService.materialsBox.get(key);
        if (info == null) continue;
        final m = info as Map;
        if ((m['material_kind_id'] as String?) != materialKindId) continue;
        final materialId = k.replaceFirst('material_text_', '');
        list.add({
          'material_id': materialId,
          'size': (m['content'] as String?)?.length ?? 0,
          'is_text': true,
        });
        continue;
      }
      final info = HiveService.materialsBox.get(key);
      if (info == null) continue;
      final m = info as Map;
      if ((m['material_kind_id'] as String?) != materialKindId) continue;
      list.add({
        'material_id': k,
        'size': m['size'] as int? ?? 0,
        'extension': m['extension'] as String?,
        'material_kind_name': m['material_kind_name'] as String?,
        'is_text': false,
      });
    }
    return list;
  }

  /// Tamanho em bytes do cache para um material kind
  int getCacheSizeByMaterialKind(String materialKindId) {
    return getCachedMaterialsByKind(materialKindId)
        .fold<int>(0, (sum, e) => sum + (e['size'] as int? ?? 0));
  }

  /// Remove todos os materiais de um material kind do cache
  Future<void> removeByMaterialKind(String materialKindId) async {
    final toRemove = getCachedMaterialsByKind(materialKindId);
    for (final e in toRemove) {
      final materialId = e['material_id'] as String?;
      if (materialId == null) continue;
      if (e['is_text'] == true) {
        await removeMaterialText(materialId);
      } else {
        await removeMaterial(materialId);
      }
    }
    final removed = getRemovedMaterialKindIds();
    removed.remove(materialKindId);
    await setRemovedMaterialKindIds(removed);
  }

  /// Cacheia conteúdo de texto de um material
  Future<void> cacheMaterialText(
    String materialId,
    String content, {
    String? materialKindId,
    String? materialKindName,
  }) async {
    final key = 'material_text_$materialId';
    final meta = <String, dynamic>{
      'content': content,
      'cached_at': DateTime.now().toIso8601String(),
    };
    if (materialKindId != null) meta['material_kind_id'] = materialKindId;
    if (materialKindName != null) meta['material_kind_name'] = materialKindName;
    await HiveService.materialsBox.put(key, meta);
  }

  /// Obtém conteúdo de texto de um material do cache
  String? getCachedMaterialText(String materialId) {
    final cacheInfo = HiveService.materialsBox.get('material_text_$materialId');
    if (cacheInfo == null) {
      return null;
    }

    try {
      final data = cacheInfo as Map;
      return data['content'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Remove conteúdo de texto de um material do cache
  Future<void> removeMaterialText(String materialId) async {
    await HiveService.materialsBox.delete('material_text_$materialId');
  }

  /// Verifica se conteúdo de texto está em cache
  bool isMaterialTextCached(String materialId) {
    return HiveService.materialsBox.get('material_text_$materialId') != null;
  }

  // ---------- Material kinds marcados como removidos no servidor (antigos) ----------
  static const String _keyRemovedKinds = 'material_kinds_marked_removed';

  /// IDs de material kinds que estão em cache mas não existem mais na API (antigos).
  Set<String> getRemovedMaterialKindIds() {
    final raw = HiveService.metadataBox.get(_keyRemovedKinds);
    if (raw == null) return {};
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toSet();
    }
    return {};
  }

  /// Persiste a lista de material kind IDs marcados como removidos no servidor.
  Future<void> setRemovedMaterialKindIds(Set<String> ids) async {
    await HiveService.metadataBox.put(_keyRemovedKinds, ids.toList());
  }

  /// Atualiza a lista de kinds "removidos" comparando cache com a lista atual da API.
  /// Deve ser chamado quando online (ex.: ao abrir a tela Materiais offline).
  Future<void> updateRemovedKindsFromApi(List<String> apiKindIds) async {
    final cached = getCachedMaterialKindIds();
    final apiSet = apiKindIds.toSet();
    final removed = cached.where((id) => !apiSet.contains(id)).toSet();
    await setRemovedMaterialKindIds(removed);
  }
}
