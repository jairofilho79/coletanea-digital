import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_service.dart';
import 'material_cache_service.dart';
import '../../features/reader/data/services/material_content_service.dart';

/// Provider for metadata box
final metadataBoxProvider = Provider<Box>((ref) {
  return HiveService.metadataBox;
});

/// Provider for materials box
final materialsBoxProvider = Provider<Box>((ref) {
  return HiveService.materialsBox;
});

/// Provider for lists box
final listsBoxProvider = Provider<Box>((ref) {
  return HiveService.listsBox;
});

/// Provider for rooms box
final roomsBoxProvider = Provider<Box>((ref) {
  return HiveService.roomsBox;
});

/// Provider for settings box
final settingsBoxProvider = Provider<Box>((ref) {
  return HiveService.settingsBox;
});

/// Provider for praises box
final praisesBoxProvider = Provider<Box>((ref) {
  return HiveService.praisesBox;
});

/// Provider for playlist materiais box
final playlistMateriaisBoxProvider = Provider<Box>((ref) {
  return HiveService.playlistMateriaisBox;
});

/// Provider for MaterialCacheService
final materialCacheServiceProvider = Provider<MaterialCacheService>((ref) {
  return MaterialCacheService();
});

/// Provider for MaterialContentService
final materialContentServiceProvider = Provider((ref) {
  final cacheService = ref.read(materialCacheServiceProvider);
  return MaterialContentService(cacheService: cacheService);
});
