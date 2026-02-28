import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_bar_title_with_logo.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/storage/providers.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../salas/presentation/providers/sala_providers.dart';
import '../../../salas/domain/entities/playlist_material.dart';
import '../../data/services/material_content_service.dart';

/// Linha parseada com informações de formatação
class ParsedLine {
  final String content;
  final bool isBold;
  final bool hasSpaceBefore;

  ParsedLine({
    required this.content,
    this.isBold = false,
    this.hasSpaceBefore = false,
  });
}

/// Página parseada contendo linhas
class ParsedPage {
  final List<ParsedLine> lines;

  ParsedPage(this.lines);
}

/// Leitor de lyrics (texto) com scroll vertical, formatação especial e cache
class LyricsReaderPage extends ConsumerStatefulWidget {
  final String materialId;
  final String materialPath;
  final String? materialName;
  final String? materialKindId;
  final String? materialKindName;
  final String? salaId; // ID da sala se vindo de uma sala
  final String? participanteId; // ID do participante
  final int? materialIndex; // Índice do material na playlist

  const LyricsReaderPage({
    super.key,
    required this.materialId,
    required this.materialPath,
    this.materialName,
    this.materialKindId,
    this.materialKindName,
    this.salaId,
    this.participanteId,
    this.materialIndex,
  });

  @override
  ConsumerState<LyricsReaderPage> createState() => _LyricsReaderPageState();
}

class _LyricsReaderPageState extends ConsumerState<LyricsReaderPage> {
  String? _content;
  bool _isLoading = true;
  String? _error;
  List<ParsedPage> _pages = [];
  int _currentPage = 0;
  double _fontSize = 16.0;
  bool _isDarkMode = false; // Padrão: modo claro
  bool _isVerticalScroll = true; // Padrão: scroll vertical
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  List<GlobalKey> _pageKeys = [];
  List<double> _pageOffsets = [];

  @override
  void initState() {
    super.initState();
    _loadFontSize();
    _loadTheme();
    _loadScrollMode();
    _loadLyrics();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Carrega tamanho da fonte salvo no Hive
  void _loadFontSize() {
    final savedSize = HiveService.settingsBox.get('lyricsReaderFontSize');
    if (savedSize != null && savedSize is double) {
      setState(() {
        _fontSize = savedSize.clamp(12.0, 48.0);
      });
    }
  }

  /// Salva tamanho da fonte no Hive
  Future<void> _saveFontSize() async {
    await HiveService.settingsBox.put('lyricsReaderFontSize', _fontSize);
  }

  /// Carrega preferência de tema do Hive
  void _loadTheme() {
    final savedTheme = HiveService.settingsBox.get('lyricsReaderDarkMode');
    if (savedTheme != null && savedTheme is bool) {
      setState(() {
        _isDarkMode = savedTheme;
      });
    }
    // Padrão é false (modo claro), então não precisa setar se não houver valor salvo
  }

  /// Salva preferência de tema no Hive
  Future<void> _saveTheme() async {
    await HiveService.settingsBox.put('lyricsReaderDarkMode', _isDarkMode);
  }

  /// Carrega preferência de modo de scroll do Hive
  void _loadScrollMode() {
    final savedMode = HiveService.settingsBox.get('lyricsReaderVerticalScroll');
    if (savedMode != null && savedMode is bool) {
      setState(() {
        _isVerticalScroll = savedMode;
      });
    }
    // Padrão é true (scroll vertical), então não precisa setar se não houver valor salvo
  }

  /// Salva preferência de modo de scroll no Hive
  Future<void> _saveScrollMode() async {
    await HiveService.settingsBox.put('lyricsReaderVerticalScroll', _isVerticalScroll);
  }

  /// Alterna entre scroll vertical e horizontal
  void _toggleScrollMode() {
    setState(() {
      _isVerticalScroll = !_isVerticalScroll;
      _currentPage = 0; // Resetar para primeira página ao alternar
    });
    _saveScrollMode();
    
    // Resetar posição ao alternar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isVerticalScroll) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        // Recalcular offsets após mudar para modo vertical
        _calculatePageOffsets();
      } else {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      }
    });
  }

  /// Alterna entre modo claro e escuro
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveTheme();
  }

  /// Carrega conteúdo do material
  Future<void> _loadLyrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contentService = ref.read(materialContentServiceProvider);
      final content = await contentService.getMaterialContent(
        widget.materialId,
        widget.materialPath,
        materialKindId: widget.materialKindId,
        materialKindName: widget.materialKindName,
      );

      setState(() {
        _content = content;
        _pages = _parseLyricsToPages(content);
        _currentPage = 0;
        _isLoading = false;
      });

      // Inicializar keys para cada página
      _pageKeys = List.generate(_pages.length, (index) => GlobalKey());
      
      // Resetar posição ao carregar
      if (_isVerticalScroll) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      } else {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      }
      
      // Calcular offsets após o primeiro frame (apenas para modo vertical)
      if (_isVerticalScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculatePageOffsets();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        final isNetworkError = e is DioException &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout);
        _error = isNetworkError
            ? 'Você está offline e este material não está disponível no dispositivo. Conecte-se para baixar ou acesse a tela "Materiais offline" para gerenciar o cache.'
            : 'Erro ao carregar letra: $e';
      });
    }
  }

  /// Calcula posições Y de cada página
  void _calculatePageOffsets() {
    _pageOffsets.clear();
    double currentOffset = 0;

    for (final key in _pageKeys) {
      final context = key.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          _pageOffsets.add(currentOffset);
          currentOffset += renderBox.size.height;
        }
      }
    }
  }

  /// Listener de scroll para atualizar página atual
  void _onScroll() {
    if (!_scrollController.hasClients || _pageOffsets.isEmpty) return;

    final scrollPosition = _scrollController.offset;
    int newPage = 0;

    for (int i = 0; i < _pageOffsets.length; i++) {
      if (scrollPosition >= _pageOffsets[i]) {
        newPage = i;
      } else {
        break;
      }
    }

    if (newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
      });
    }
  }

  /// Parse do texto em páginas com formatação especial
  List<ParsedPage> _parseLyricsToPages(String text) {
    final lines = text.split(RegExp(r'\r?\n'));
    final pages = <ParsedPage>[];
    var currentPage = <ParsedLine>[];

    for (final line in lines) {
      final trimmed = line.trim();

      // Linha em branco = fim da página
      if (trimmed.isEmpty) {
        if (currentPage.isNotEmpty) {
          pages.add(ParsedPage(currentPage));
          currentPage = [];
        }
        continue;
      }

      // Linha começando com / = adicionar espaço antes
      if (trimmed.startsWith('/')) {
        final content = trimmed.substring(1).trim();
        currentPage.add(ParsedLine(
          content: content,
          hasSpaceBefore: true,
        ));
        continue;
      }

      // Linha começando com * = negrito
      if (trimmed.startsWith('*')) {
        final content = trimmed.substring(1).trim();
        currentPage.add(ParsedLine(
          content: content,
          isBold: true,
        ));
        continue;
      }

      // Linha normal
      currentPage.add(ParsedLine(content: line));
    }

    // Adicionar última página se houver conteúdo
    if (currentPage.isNotEmpty) {
      pages.add(ParsedPage(currentPage));
    }

    // Se não houver páginas, criar uma página vazia
    if (pages.isEmpty) {
      pages.add(ParsedPage([]));
    }

    return pages;
  }

  /// Processa conteúdo da linha para destacar texto entre parênteses
  List<TextSpan> _processLineContent(String line) {
    final upperLine = line.toUpperCase();
    final spans = <TextSpan>[];
    final regex = RegExp(r'\(([^)]+)\)');
    var lastIndex = 0;

    for (final match in regex.allMatches(upperLine)) {
      // Texto antes do parêntese
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: upperLine.substring(lastIndex, match.start),
        ));
      }

      // Texto entre parênteses em amarelo
      spans.add(TextSpan(
        text: '(${match.group(1)})',
        style: TextStyle(color: Colors.yellow[700]),
      ));

      lastIndex = match.end;
    }

    // Texto restante
    if (lastIndex < upperLine.length) {
      spans.add(TextSpan(
        text: upperLine.substring(lastIndex),
      ));
    }

    return spans.isEmpty ? [TextSpan(text: upperLine)] : spans;
  }

  /// Aumenta tamanho da fonte
  void _increaseFontSize() {
    if (_fontSize < 48.0) {
      setState(() {
        _fontSize = (_fontSize + 2.0).clamp(12.0, 48.0);
      });
      _saveFontSize();
      // Recalcular offsets após mudança de fonte
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculatePageOffsets();
      });
    }
  }

  /// Diminui tamanho da fonte
  void _decreaseFontSize() {
    if (_fontSize > 12.0) {
      setState(() {
        _fontSize = (_fontSize - 2.0).clamp(12.0, 48.0);
      });
      _saveFontSize();
      // Recalcular offsets após mudança de fonte
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculatePageOffsets();
      });
    }
  }

  /// Vai para página anterior
  void _previousPage() {
    if (_currentPage > 0) {
      if (_isVerticalScroll) {
        // Scroll vertical
        if (_pageOffsets.isNotEmpty) {
          final targetPage = _currentPage - 1;
          if (targetPage < _pageOffsets.length) {
            _scrollController.animateTo(
              _pageOffsets[targetPage],
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      } else {
        // PageView horizontal
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// Vai para próxima página
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      if (_isVerticalScroll) {
        // Scroll vertical
        if (_pageOffsets.isNotEmpty) {
          final targetPage = _currentPage + 1;
          if (targetPage < _pageOffsets.length) {
            _scrollController.animateTo(
              _pageOffsets[targetPage],
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      } else {
        // PageView horizontal
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// Copia conteúdo para área de transferência
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

  /// Cores dinâmicas baseadas no tema
  Color get _backgroundColor => _isDarkMode ? Colors.black : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : Colors.black87;
  Color get _dividerColor => _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
  Color get _emptyTextColor => _isDarkMode ? Colors.white70 : Colors.grey[600]!;

  /// Widget para renderizar uma página
  Widget _buildPage(ParsedPage page, int index) {
    final content = Container(
      key: _isVerticalScroll ? _pageKeys[index] : null,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (page.lines.isEmpty)
                Text(
                  'NENHUM CONTEÚDO',
                  style: TextStyle(
                    fontSize: _fontSize,
                    color: _emptyTextColor,
                  ),
                )
              else
                ...page.lines.map((line) {
                  final widgets = <Widget>[];

                  if (line.hasSpaceBefore) {
                    widgets.add(SizedBox(height: _fontSize * 1.5));
                  }

                  widgets.add(
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: _fontSize,
                          height: 1.6,
                          fontWeight: line.isBold ? FontWeight.bold : FontWeight.normal,
                          color: _textColor,
                        ),
                        children: _processLineContent(line.content),
                      ),
                    ),
                  );

                  return Column(children: widgets);
                }).toList(),
            ],
          ),
        ),
      ),
    );

    // No modo horizontal, envolver em SingleChildScrollView para permitir scroll vertical
    if (!_isVerticalScroll) {
      return SingleChildScrollView(
        child: content,
      );
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        leading: widget.salaId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/salas/${widget.salaId}'),
                tooltip: 'Voltar para playlist',
              )
            : const BackButtonWithDrawerOnLongPress(),
        title: AppBarTitleWithLogo(
          title: Text(widget.materialName ?? 'Letra'),
        ),
        actions: [
          // Botão próximo material quando vindo de sala
          if (widget.salaId != null && widget.participanteId != null && widget.materialIndex != null)
            _buildNextMaterialButton(context),
          if (_content != null)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copiar letra',
              onPressed: _copyToClipboard,
            ),
        ],
      ),
      body: Container(
        color: _backgroundColor,
        child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _textColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLyrics,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _pages.isEmpty
                  ? Center(
                      child: Text(
                        'Letra não disponível',
                        style: TextStyle(color: _textColor),
                      ),
                    )
                  : Column(
                      children: [
                        // Controles superiores (fundo vermelho padrão, botões dourados)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B2D2B),
                            border: Border(
                              bottom: BorderSide(
                                color: const Color(0xFFD4AF37),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Controles de fonte (esquerda)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: _decreaseFontSize,
                                    tooltip: 'Diminuir fonte',
                                    color: _fontSize <= 12.0 ? Colors.grey : const Color(0xFFD4AF37),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5E6D3),
                                      border: Border.all(
                                        color: const Color(0xFFD4AF37),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_fontSize.toInt()}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5A2A2A),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: _increaseFontSize,
                                    tooltip: 'Aumentar fonte',
                                    color: _fontSize >= 48.0 ? Colors.grey : const Color(0xFFD4AF37),
                                  ),
                                ],
                              ),
                              // Toggle de tema (centro)
                              IconButton(
                                icon: Icon(_isDarkMode ? Icons.nightlight_round : Icons.wb_sunny),
                                onPressed: _toggleTheme,
                                tooltip: _isDarkMode ? 'Modo escuro' : 'Modo claro',
                                color: const Color(0xFFD4AF37),
                              ),
                              // Botão único que alterna entre modo vertical e horizontal
                              IconButton(
                                icon: Icon(
                                  _isVerticalScroll ? Icons.swap_vert : Icons.swap_horiz,
                                ),
                                onPressed: _toggleScrollMode,
                                tooltip: _isVerticalScroll
                                    ? 'Alternar para modo horizontal'
                                    : 'Alternar para modo vertical',
                                color: const Color(0xFFD4AF37),
                              ),
                            ],
                          ),
                        ),
                        // Área de conteúdo (vertical ou horizontal)
                        Expanded(
                          child: _isVerticalScroll
                              ? SingleChildScrollView(
                                  controller: _scrollController,
                                  child: Column(
                                    children: [
                                      ..._pages.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final page = entry.value;
                                        return Column(
                                          children: [
                                            _buildPage(page, index),
                                            // Barra delimitadora (exceto na última página)
                                            if (index < _pages.length - 1)
                                              Divider(
                                                height: 40,
                                                thickness: 1,
                                                color: _dividerColor,
                                              ),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                )
                              : PageView.builder(
                                  controller: _pageController,
                                  itemCount: _pages.length,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    return _buildPage(_pages[index], index);
                                  },
                                ),
                        ),
                        // Controles inferiores (fundo vermelho padrão, borda e botões dourados)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B2D2B),
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFFD4AF37),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _currentPage > 0 ? _previousPage : null,
                                icon: const Icon(Icons.chevron_left),
                                label: const Text('Anterior'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _currentPage > 0
                                        ? const Color(0xFFD4AF37)
                                        : Colors.grey,
                                  ),
                                  foregroundColor: const Color(0xFFD4AF37),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5E6D3),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Página ${_currentPage + 1} de ${_pages.length}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5A2A2A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: _currentPage < _pages.length - 1 ? _nextPage : null,
                                icon: const Icon(Icons.chevron_right),
                                label: const Text('Próxima'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _currentPage < _pages.length - 1
                                        ? const Color(0xFFD4AF37)
                                        : Colors.grey,
                                  ),
                                  foregroundColor: const Color(0xFFD4AF37),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
      ),
      floatingActionButton: widget.salaId != null && widget.participanteId != null && widget.materialIndex != null
          ? FloatingActionButton(
              onPressed: () => _navigateToNextMaterial(context),
              child: const Icon(Icons.arrow_forward),
              tooltip: 'Próximo material',
            )
          : null,
    );
  }

  Widget _buildNextMaterialButton(BuildContext context) {
    return FutureBuilder<List<MaterialNaPlaylist>>(
      future: ref.read(playlistMateriaisProvider(PlaylistParams(salaId: widget.salaId!)).future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final materiais = snapshot.data!;
        final hasNext = widget.materialIndex! < materiais.length - 1;
        if (!hasNext) return const SizedBox.shrink();
        
        return IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => _navigateToNextMaterial(context),
          tooltip: 'Próximo material',
        );
      },
    );
  }

  void _navigateToNextMaterial(BuildContext context) async {
    if (widget.salaId == null || widget.participanteId == null || widget.materialIndex == null) return;
    
    final materiais = await ref.read(playlistMateriaisProvider(PlaylistParams(salaId: widget.salaId!)).future);
    
    final nextIndex = widget.materialIndex! + 1;
    if (nextIndex >= materiais.length) return;
    
    final nextMaterial = materiais[nextIndex];
    final materialPath = ''; // TODO: obter path do material
    
    if (nextMaterial.tipoMaterial == 'pdf') {
      context.pushReplacement(
        '/reader/pdf/${nextMaterial.materialId}?path=$materialPath&name=${nextMaterial.nomeMaterial}&salaId=${widget.salaId}&participanteId=${widget.participanteId}&materialIndex=$nextIndex',
      );
    } else if (nextMaterial.tipoMaterial == 'lyrics') {
      context.pushReplacement(
        '/reader/lyrics/${nextMaterial.materialId}?path=$materialPath&name=${nextMaterial.nomeMaterial}&salaId=${widget.salaId}&participanteId=${widget.participanteId}&materialIndex=$nextIndex',
      );
    }
  }
}
