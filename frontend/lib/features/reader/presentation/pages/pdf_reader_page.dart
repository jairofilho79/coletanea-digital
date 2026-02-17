import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/storage/providers.dart';
import '../../../../core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Leitor de PDF com suporte offline
/// Baixa os bytes do PDF via API e renderiza com pdfrx
class PdfReaderPage extends ConsumerStatefulWidget {
  final String materialId;
  final String materialPath;
  final String? materialName;

  const PdfReaderPage({
    super.key,
    required this.materialId,
    required this.materialPath,
    this.materialName,
  });

  @override
  ConsumerState<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends ConsumerState<PdfReaderPage> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _error;
  late PdfViewerController _controller;
  int _currentPage = 1;
  int _totalPages = 0;
  late VoidCallback _pageListener;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _pageListener = () {
      if (_controller.isReady) {
        final currentPage = _controller.pageNumber ?? 1;
        final totalPages = _controller.pageCount;
        if (currentPage != _currentPage || totalPages != _totalPages) {
          if (mounted) {
            setState(() {
              _currentPage = currentPage;
              _totalPages = totalPages;
            });
          }
        }
      }
    };
    _controller.addListener(_pageListener);
    _loadPdf();
  }

  /// Constrói a URL de download exatamente como o coldigom frontend faz:
  /// ${baseUrl}/api/v1/praise-materials/${id}/download
  String _buildDownloadUrl() {
    final baseUrl = AppConfig.coldigomApiBaseUrl;
    return '$baseUrl/api/v1/praise-materials/${widget.materialId}/download';
  }

  Future<void> _loadPdf() async {
    try {
      // Validação: se parece ser texto em vez de arquivo PDF
      if (widget.materialPath.isNotEmpty &&
          !widget.materialPath.contains('.pdf') &&
          !widget.materialPath.contains('/') &&
          widget.materialPath.length > 100) {
        setState(() {
          _isLoading = false;
          _error = 'Este material é texto (letra), não um arquivo PDF.';
        });
        return;
      }

      // Plataformas não-web: tenta cache primeiro
      if (!kIsWeb) {
        final cacheService = ref.read(materialCacheServiceProvider);
        final cached = cacheService.getCachedMaterial(widget.materialId);
        if (cached != null && await cached.exists()) {
          final bytes = await cached.readAsBytes();
          setState(() {
            _pdfBytes = bytes;
            _isLoading = false;
          });
          return;
        }
      }

      // Baixa os bytes do PDF via API (igual coldigom frontend)
      await _downloadPdfBytes();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao carregar PDF: $e';
      });
    }
  }

  Future<void> _downloadPdfBytes() async {
    final downloadUrl = _buildDownloadUrl();
    debugPrint('Baixando PDF de: $downloadUrl');

    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data!);

        // Valida header PDF (%PDF)
        if (bytes.length < 4 ||
            String.fromCharCodes(bytes.sublist(0, 4)) != '%PDF') {
          setState(() {
            _isLoading = false;
            _error = 'O arquivo retornado não é um PDF válido.\n'
                'Pode ser uma página de erro ou texto.';
          });
          return;
        }

        // Salva no cache (apenas plataformas não-web)
        if (!kIsWeb) {
          final cacheService = ref.read(materialCacheServiceProvider);
          await cacheService.cacheMaterial(
            materialId: widget.materialId,
            extension: 'pdf',
            data: bytes,
          );
        }

        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao baixar PDF: Status ${response.statusCode}';
        });
      }
    } on DioException catch (e) {
      String errorMsg;
      if (e.response?.statusCode == 404) {
        errorMsg = 'PDF não encontrado no servidor (404).\n'
            'O arquivo pode ter sido removido.';
      } else if (e.response?.statusCode == 400) {
        errorMsg = 'Este material não é um arquivo PDF (400).\n'
            'Pode ser texto ou outro tipo.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Timeout ao baixar PDF.\nVerifique sua conexão.';
      } else {
        errorMsg = 'Erro ao baixar PDF: ${e.message}';
      }
      setState(() {
        _isLoading = false;
        _error = errorMsg;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro inesperado: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButtonWithDrawerOnLongPress(),
        title: Text(widget.materialName ?? 'PDF'),
        actions: [
          // Indicador de página: "1 de X" (só mostra quando PDF carregado e páginas disponíveis)
          if (_pdfBytes != null && _totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '$_currentPage de $_totalPages',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          // Botão de opções (3 pontos verticais)
          // Preparado para futuras opções (download, compartilhar, etc.)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Opções',
            onSelected: (value) {
              // Futuramente: implementar ações do menu
              // Exemplo:
              // if (value == 'download') {
              //   // Implementar download
              // } else if (value == 'share') {
              //   // Implementar compartilhamento
              // }
            },
            itemBuilder: (context) => [
              // Por enquanto, menu preparado para futuras opções
              // Quando adicionar opções reais, remover este item temporário:
              const PopupMenuItem(
                value: 'placeholder',
                enabled: false,
                child: Text(
                  'Opções em breve',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
              // Exemplo de opções futuras:
              // const PopupMenuItem(
              //   value: 'download',
              //   child: Row(
              //     children: [
              //       Icon(Icons.download, size: 20),
              //       SizedBox(width: 12),
              //       Text('Baixar PDF'),
              //     ],
              //   ),
              // ),
              // const PopupMenuItem(
              //   value: 'share',
              //   child: Row(
              //     children: [
              //       Icon(Icons.share, size: 20),
              //       SizedBox(width: 12),
              //       Text('Compartilhar'),
              //     ],
              //   ),
              // ),
            ],
          ),
          // Indicador de cache offline (apenas plataformas não-web)
          if (_pdfBytes != null && !kIsWeb)
            const IconButton(
              icon: Icon(Icons.download_done),
              tooltip: 'Disponível offline',
              onPressed: null,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando PDF...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                    _pdfBytes = null;
                  });
                  _loadPdf();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes != null) {
      return GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe para esquerda (arrastar da direita para esquerda) → próxima página
          // Como virar página de um livro (puxa para esquerda para avançar)
          if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
            _goToNextPage();
          }
          // Swipe para direita (arrastar da esquerda para direita) → página anterior
          // Como voltar página de um livro (puxa para direita para voltar)
          else if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
            _goToPreviousPage();
          }
        },
        child: PdfViewer.data(
          _pdfBytes!,
          sourceName: widget.materialName ?? 'material.pdf',
          controller: _controller,
        ),
      );
    }

    return const Center(child: Text('PDF não disponível'));
  }

  /// Navega para a próxima página
  void _goToNextPage() {
    if (!_controller.isReady) return;
    
    final currentPage = _controller.pageNumber ?? 1;
    final totalPages = _controller.pageCount;
    
    if (currentPage < totalPages) {
      _controller.goToPage(
        pageNumber: currentPage + 1,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  /// Navega para a página anterior
  void _goToPreviousPage() {
    if (!_controller.isReady) return;
    
    final currentPage = _controller.pageNumber ?? 1;
    
    if (currentPage > 1) {
      _controller.goToPage(
        pageNumber: currentPage - 1,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_pageListener);
    super.dispose();
  }
}
