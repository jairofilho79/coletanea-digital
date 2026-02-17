import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/storage/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Leitor de lyrics (texto) com suporte offline
class LyricsReaderPage extends ConsumerStatefulWidget {
  final String materialId;
  final String materialPath;
  final String? materialName;

  const LyricsReaderPage({
    super.key,
    required this.materialId,
    required this.materialPath,
    this.materialName,
  });

  @override
  ConsumerState<LyricsReaderPage> createState() => _LyricsReaderPageState();
}

class _LyricsReaderPageState extends ConsumerState<LyricsReaderPage> {
  File? _cachedFile;
  String? _content;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    try {
      final cacheService = ref.read(materialCacheServiceProvider);
      
      // Verifica se está em cache
      final cached = cacheService.getCachedMaterial(widget.materialId);
      if (cached != null && await cached.exists()) {
        final content = await cached.readAsString();
        setState(() {
          _cachedFile = cached;
          _content = content;
          _isLoading = false;
        });
        return;
      }

      // TODO: Baixar do coldigom se não estiver em cache
      setState(() {
        _isLoading = false;
        _error = 'Letra não encontrada no cache. Download será implementado em breve.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao carregar letra: $e';
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_content != null) {
      await Clipboard.setData(ClipboardData(text: _content!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Letra copiada para a área de transferência')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButtonWithDrawerOnLongPress(),
        title: Text(widget.materialName ?? 'Letra'),
        actions: [
          if (_cachedFile != null)
            IconButton(
              icon: const Icon(Icons.download_done),
              tooltip: 'Arquivo em cache (offline)',
              onPressed: null,
            ),
          if (_content != null)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copiar letra',
              onPressed: _copyToClipboard,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!),
                    ],
                  ),
                )
              : _content != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _content!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              fontSize: 16,
                            ),
                      ),
                    )
                  : const Center(child: Text('Letra não disponível')),
    );
  }
}
