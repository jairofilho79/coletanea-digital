import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../connectivity/connectivity_provider.dart';
import 'providers.dart';

/// Dispara revalidação do cache de metadados ao iniciar o app (se online) e
/// quando a conectividade passar de offline para online.
class MetadataRevalidationBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const MetadataRevalidationBootstrap({super.key, required this.child});

  @override
  ConsumerState<MetadataRevalidationBootstrap> createState() =>
      _MetadataRevalidationBootstrapState();
}

class _MetadataRevalidationBootstrapState
    extends ConsumerState<MetadataRevalidationBootstrap> {
  bool _startupDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runRevalidationOnce());
  }

  void _runRevalidationOnce() {
    if (_startupDone) return;
    _startupDone = true;
    final isOnline = ref.read(connectivityStatusProvider).value ?? false;
    ref.read(metadataRevalidationRunnerProvider).revalidateIfNeeded(isOnline);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityStatusProvider, (prev, next) {
      next.whenData((isOnline) {
        if (isOnline) {
          ref.read(metadataRevalidationRunnerProvider).revalidateIfNeeded(true);
        }
      });
    });
    return widget.child;
  }
}
