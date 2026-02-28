import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que expõe se há conectividade (wifi ou mobile).
/// Não garante internet real; use para UX (desabilitar "Baixar" quando offline).
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>.broadcast();
  final connectivity = Connectivity();

  void emit(bool online) {
    if (!controller.isClosed) controller.add(online);
  }

  connectivity.checkConnectivity().then((results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    emit(online);
  });

  final sub = connectivity.onConnectivityChanged.listen((results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    emit(online);
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider síncrono que lê o último valor do stream (ou null antes do primeiro emit).
final isOnlineProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(connectivityStatusProvider);
});
