import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../audio/global_audio_player_provider.dart';
import '../audio/global_audio_state.dart';
import '../config/app_config.dart';

/// Permite abrir o drawer da raiz a partir de qualquer página.
class RootDrawerScope extends InheritedWidget {
  final VoidCallback openDrawer;

  const RootDrawerScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  static RootDrawerScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RootDrawerScope>();
    assert(scope != null, 'RootDrawerScope not found');
    return scope!;
  }

  static RootDrawerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RootDrawerScope>();
  }

  @override
  bool updateShouldNotify(RootDrawerScope oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}

/// Shell que envolve todas as rotas e fornece o Drawer com menu e controles de áudio.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return RootDrawerScope(
      openDrawer: _openDrawer,
      child: Scaffold(
        key: _scaffoldKey,
        body: widget.child,
        drawer: const _AppDrawer(),
        drawerEdgeDragWidth: 0,
      ),
    );
  }
}

/// Botão de voltar que, ao manter pressionado (long press), abre o drawer.
/// Use como [AppBar.leading] nas telas que têm botão de voltar.
class BackButtonWithDrawerOnLongPress extends StatelessWidget {
  const BackButtonWithDrawerOnLongPress({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = RootDrawerScope.maybeOf(context);
    return Tooltip(
      message: 'Voltar (segure para abrir menu)',
      child: GestureDetector(
        onTap: () => context.pop(),
        onLongPress: scope != null ? () => scope.openDrawer() : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.iconTheme?.color ??
                Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(globalAudioPlayerProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppConfig.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
            ),
            if (audioState.hasTrack) ...[
              _AudioDrawerContent(state: audioState),
              const Divider(height: 1),
            ],
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.music_note),
                    title: const Text('Louvores'),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (GoRouterState.of(context).uri.path != '/' &&
                          GoRouterState.of(context).uri.path != '/praises') {
                        context.go('/');
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list),
                    title: const Text('Listas'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/listas');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.room),
                    title: const Text('Salas'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/salas');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioDrawerContent extends ConsumerWidget {
  final GlobalAudioState state;

  const _AudioDrawerContent({required this.state});

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = state.track!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t.praiseName != null && t.praiseName!.isNotEmpty)
                      Text(
                        t.praiseName!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (t.materialKindName != null &&
                        t.materialKindName!.isNotEmpty)
                      Text(
                        t.materialKindName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Fechar player',
                onPressed: () {
                  ref.read(globalAudioPlayerProvider.notifier).close();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                state.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: state.duration.inMilliseconds > 0
                    ? (state.position.inMilliseconds /
                            state.duration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0,
                onChanged: state.duration.inMilliseconds > 0
                    ? (v) {
                        final pos = Duration(
                          milliseconds: (v * state.duration.inMilliseconds)
                              .round(),
                        );
                        ref
                            .read(globalAudioPlayerProvider.notifier)
                            .seek(pos);
                      }
                    : null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(state.position),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  _formatDuration(state.duration),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_5),
                  onPressed: () =>
                      ref.read(globalAudioPlayerProvider.notifier).seekBackward(),
                  tooltip: 'Voltar 5s',
                ),
                IconButton.filled(
                  icon: Icon(
                    state.isAtEnd
                        ? Icons.replay
                        : (state.isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                  onPressed: () =>
                      ref.read(globalAudioPlayerProvider.notifier).togglePlayPause(),
                  tooltip: state.isAtEnd
                      ? 'Recomeçar'
                      : (state.isPlaying ? 'Pausar' : 'Reproduzir'),
                ),
                IconButton(
                  icon: const Icon(Icons.forward_5),
                  onPressed: () =>
                      ref.read(globalAudioPlayerProvider.notifier).seekForward(),
                  tooltip: 'Avançar 5s',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
