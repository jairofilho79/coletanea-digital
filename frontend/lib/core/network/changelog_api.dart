import 'package:dio/dio.dart';

import 'coldigom_client.dart';

/// Resposta de GET /api/v1/changelog/version
class ChangelogVersionResponse {
  final int currentVersion;

  const ChangelogVersionResponse({required this.currentVersion});

  factory ChangelogVersionResponse.fromJson(Map<String, dynamic> json) {
    return ChangelogVersionResponse(
      currentVersion: (json['current_version'] as num).toInt(),
    );
  }
}

/// Uma entrada do changelog (entity_type, entity_id, action, etc.)
class ChangelogEntry {
  final int version;
  final String entityType;
  final String entityId;
  final String action;
  final String? createdAt;

  const ChangelogEntry({
    required this.version,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.createdAt,
  });

  factory ChangelogEntry.fromJson(Map<String, dynamic> json) {
    return ChangelogEntry(
      version: (json['version'] as num).toInt(),
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      action: json['action'] as String,
      createdAt: json['created_at'] as String?,
    );
  }
}

/// Resposta de GET /api/v1/changelog/?since_version=n
class ChangelogResponse {
  final int currentVersion;
  final List<ChangelogEntry> changes;

  const ChangelogResponse({
    required this.currentVersion,
    required this.changes,
  });

  factory ChangelogResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['changes'];
    final list = raw is List
        ? raw
            .where((e) => e is Map<String, dynamic>)
            .map((e) => ChangelogEntry.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList()
        : <ChangelogEntry>[];
    return ChangelogResponse(
      currentVersion: (json['current_version'] as num).toInt(),
      changes: list,
    );
  }
}

const String _versionPath = '/api/v1/changelog/version';
const String _changelogPath = '/api/v1/changelog';

/// Cliente da Changelog API do coldigom (endpoints públicos, rate limit 200/min
/// changelog, 600/min version). Usa [ColdigomClient] com retry 429.
class ChangelogApi {
  ChangelogApi(this._client);

  final ColdigomClient _client;

  /// GET /api/v1/changelog/version → current_version (leve, para polling).
  /// [DioException] em erro de rede ou 4xx/5xx.
  Future<ChangelogVersionResponse> getVersion() async {
    final response = await _client.get<Map<String, dynamic>>(
      _versionPath,
      maxRetries: 3,
    );
    final data = response.data;
    if (data == null) throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
    return ChangelogVersionResponse.fromJson(data);
  }

  /// GET /api/v1/changelog/?since_version=n. since_version=0 retorna tudo (sync
  /// inicial). [DioException] em erro de rede ou 4xx/5xx.
  Future<ChangelogResponse> getChangelog({required int sinceVersion}) async {
    final response = await _client.get<Map<String, dynamic>>(
      _changelogPath,
      queryParameters: {'since_version': sinceVersion},
      maxRetries: 3,
    );
    final data = response.data;
    if (data == null) throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
    return ChangelogResponse.fromJson(data);
  }
}
