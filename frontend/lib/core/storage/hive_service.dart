import 'package:hive_flutter/hive_flutter.dart';

/// Serviço para gerenciar Hive boxes
class HiveService {
  static const String _metadataBoxName = 'metadata';
  static const String _materialsBoxName = 'materials';
  static const String _listsBoxName = 'lists';
  static const String _roomsBoxName = 'rooms';
  static const String _settingsBoxName = 'settings';
  static const String _praisesBoxName = 'praises';

  /// Initialize all Hive boxes
  static Future<void> init() async {
    // Register adapters will be done here when models are created
    // await Hive.registerAdapter(PraiseAdapter());
    // await Hive.registerAdapter(MaterialAdapter());
    // etc.

    // Open boxes
    await Hive.openBox(_metadataBoxName);
    await Hive.openBox(_materialsBoxName);
    await Hive.openBox(_listsBoxName);
    await Hive.openBox(_roomsBoxName);
    await Hive.openBox(_settingsBoxName);
    await Hive.openBox(_praisesBoxName);
  }

  /// Get metadata box
  static Box get metadataBox => Hive.box(_metadataBoxName);

  /// Get materials box
  static Box get materialsBox => Hive.box(_materialsBoxName);

  /// Get lists box
  static Box get listsBox => Hive.box(_listsBoxName);

  /// Get rooms box
  static Box get roomsBox => Hive.box(_roomsBoxName);

  /// Get settings box
  static Box get settingsBox => Hive.box(_settingsBoxName);

  /// Get praises box
  static Box get praisesBox => Hive.box(_praisesBoxName);

  /// Clear all cache
  static Future<void> clearAll() async {
    await metadataBox.clear();
    await materialsBox.clear();
    await listsBox.clear();
    await roomsBox.clear();
    await praisesBox.clear();
    // Don't clear settings box
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    // This is a simplified version
    // In production, calculate actual file sizes
    return metadataBox.length + materialsBox.length;
  }
}
