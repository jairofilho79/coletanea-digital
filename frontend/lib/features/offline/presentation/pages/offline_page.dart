import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/connectivity/connectivity_provider.dart';
import '../../../../core/storage/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_title_with_logo.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/offline/offline_material_service.dart';
import '../../../../core/offline/offline_download_progress.dart';
import '../../../praises/domain/services/translation_service.dart';
import '../../../praises/presentation/providers/translation_providers.dart';
import '../providers/offline_providers.dart';

/// Conteúdo do diálogo de download em lote (evita recriar o Future a cada rebuild).
class _DownloadDialogContent extends StatefulWidget {
  final String displayName;
  final String materialKindId;
  final String materialKindName;
  final OfflineMaterialService service;
  final CancelToken cancelToken;

  const _DownloadDialogContent({
    required this.displayName,
    required this.materialKindId,
    required this.materialKindName,
    required this.service,
    required this.cancelToken,
  });

  @override
  State<_DownloadDialogContent> createState() => _DownloadDialogContentState();
}

class _DownloadDialogContentState extends State<_DownloadDialogContent> {
  OfflineDownloadProgress? _progress;
  OfflineDownloadResult? _result;

  @override
  void initState() {
    super.initState();
    widget.service
        .downloadByMaterialKind(
      widget.materialKindId,
      widget.materialKindName,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
      cancelToken: widget.cancelToken,
    )
        .then((r) {
      if (mounted) setState(() => _result = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      final r = _result!;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Concluído: ${r.completed} baixados, ${r.skipped} já em cache, ${r.failed} falhas.',
            style: const TextStyle(color: AppTheme.textColor),
          ),
          if (r.errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Falhas: ${r.errors.take(3).join(", ")}${r.errors.length > 3 ? "..." : ""}',
                style: TextStyle(color: Colors.red[300], fontSize: 12),
              ),
            ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            _progress != null
                ? (_progress!.message ?? 'Baixando ${_progress!.completed} de ${_progress!.total}...')
                : 'Baixando... Toque em Cancelar para parar.',
            style: const TextStyle(color: AppTheme.textColor),
          ),
        ),
      ],
    );
  }
}

/// Página de gestão de materiais offline (cache por material kind)
class OfflinePage extends ConsumerStatefulWidget {
  const OfflinePage({super.key});

  @override
  ConsumerState<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends ConsumerState<OfflinePage> {
  double _cacheSizeMb = 0;
  List<String> _cachedKindIds = [];
  Map<String, List<Map<String, dynamic>>> _materialsByKind = {};
  Set<String> _removedKindIds = {};
  bool _loading = true;
  CancelToken? _downloadCancelToken;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final cache = ref.read(materialCacheServiceProvider);
    final isOnline = ref.read(connectivityStatusProvider).value ?? false;
    if (isOnline) {
      try {
        final kinds = await ref.read(materialKindsFromApiProvider.future);
        await cache.updateRemovedKindsFromApi(kinds.map((k) => k.id).toList());
      } catch (_) {}
    }
    _cacheSizeMb = await cache.getCacheSizeMB();
    _cachedKindIds = cache.getCachedMaterialKindIds();
    _removedKindIds = cache.getRemovedMaterialKindIds();
    _materialsByKind = {};
    for (final kid in _cachedKindIds) {
      _materialsByKind[kid] = cache.getCachedMaterialsByKind(kid);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(translationsLoadedProvider);
    final translationService = ref.watch(translationServiceProvider);
    final connectivity = ref.watch(connectivityStatusProvider);

    return Scaffold(
      appBar: AppBar(
        leading: RootDrawerScope.maybeOf(context) != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => RootDrawerScope.of(context).openDrawer(),
                tooltip: 'Menu',
              )
            : null,
        title: AppBarTitleWithLogo.text('Materiais offline'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTotalSizeCard(),
                    const SizedBox(height: 16),
                    _buildCachedKindsList(translationService),
                    const SizedBox(height: 24),
                    _buildClearAllButton(),
                    const SizedBox(height: 24),
                    _buildDownloadSection(connectivity, translationService),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTotalSizeCard() {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.storage, size: 40, color: AppTheme.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uso em disco',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.titleColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${_cacheSizeMb.toStringAsFixed(1)} MB',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedKindsList(TranslationService translationService) {
    if (_cachedKindIds.isEmpty) {
      return Card(
        color: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhum material em cache. Use "Baixar por tipo" abaixo quando estiver online.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipos disponíveis offline',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ..._cachedKindIds.map((kindId) {
          final materials = _materialsByKind[kindId] ?? [];
          final first = materials.isNotEmpty ? materials.first : null;
          final kindName = first?['material_kind_name'] as String? ?? kindId;
          final displayName =
              translationService.getMaterialKindName(kindId, kindName);
          final cache = ref.read(materialCacheServiceProvider);
          final sizeBytes = cache.getCacheSizeByMaterialKind(kindId);
          final sizeMb = sizeBytes / (1024 * 1024);

          final isRemoved = _removedKindIds.contains(kindId);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        color: AppTheme.titleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isRemoved)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Antigo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${materials.length} materiais · ${sizeMb.toStringAsFixed(1)} MB',
                    style: const TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                  if (isRemoved)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Este tipo não existe mais no servidor. Pode haver uma nova versão.',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              children: [
                ...materials.map((m) {
                  final mid = m['material_id'] as String? ?? '';
                  final isText = m['is_text'] == true;
                  return ListTile(
                    title: Text(
                      isText ? 'Letra $mid' : 'Material $mid',
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 14,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red[700],
                      onPressed: () async {
                        final cache = ref.read(materialCacheServiceProvider);
                        if (isText) {
                          await cache.removeMaterialText(mid);
                        } else {
                          await cache.removeMaterial(mid);
                        }
                        await _refresh();
                      },
                    ),
                  );
                }),
                ListTile(
                  title: const Text(
                    'Remover todos deste tipo',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.backgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        title: const Text(
                          'Remover tipo',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                        content: Text(
                          'Remover todos os ${materials.length} materiais de "$displayName" do dispositivo?',
                          style: const TextStyle(color: AppTheme.textColor),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Remover', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && mounted) {
                      await ref.read(materialCacheServiceProvider).removeByMaterialKind(kindId);
                      await _refresh();
                    }
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildClearAllButton() {
    return OutlinedButton.icon(
      onPressed: _cachedKindIds.isEmpty
          ? null
          : () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  title: const Text(
                    'Limpar tudo',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                  content: const Text(
                    'Remover todos os materiais em cache do dispositivo?',
                    style: TextStyle(color: AppTheme.textColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Limpar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (ok == true && mounted) {
                await ref.read(materialCacheServiceProvider).clearAllMaterials();
                await _refresh();
              }
            },
      icon: const Icon(Icons.delete_sweep),
      label: const Text('Limpar todo o cache'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red[700],
        side: BorderSide(color: Colors.red[700]!),
      ),
    );
  }

  Widget _buildDownloadSection(
    AsyncValue<bool> connectivity,
    TranslationService translationService,
  ) {
    final isOnline = connectivity.value ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Baixar por tipo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        if (!isOnline)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Conecte-se à internet para baixar materiais.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final kindsAsync = ref.watch(materialKindsFromApiProvider);
            return kindsAsync.when(
              data: (kinds) {
                if (kinds.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Nenhum tipo de material disponível.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ),
                  );
                }
                return Column(
                  children: kinds.map((k) {
                    final displayName =
                        translationService.getMaterialKindName(k.id, k.name);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        displayName,
                        style: const TextStyle(color: AppTheme.textColor),
                      ),
                      trailing: ElevatedButton(
                        onPressed: !isOnline
                            ? null
                            : () => _startDownload(k.id, k.name, displayName),
                        child: const Text('Baixar todos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.btnBackgroundColor,
                          foregroundColor: AppTheme.textColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Erro ao carregar tipos: $e',
                  style: TextStyle(color: Colors.red[300]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _startDownload(
    String materialKindId,
    String materialKindName,
    String displayName,
  ) async {
    _downloadCancelToken = CancelToken();
    final service = ref.read(offlineMaterialServiceProvider);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        title: Text(
          'Baixando: $displayName',
          style: const TextStyle(color: AppTheme.primaryColor, fontSize: 18),
        ),
        content: _DownloadDialogContent(
          displayName: displayName,
          materialKindId: materialKindId,
          materialKindName: materialKindName,
          service: service,
          cancelToken: _downloadCancelToken!,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _downloadCancelToken?.cancel('user');
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
    if (mounted) await _refresh();
  }
}
