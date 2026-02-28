import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/material_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Hive boxes
  await HiveService.init();
  
  // Initialize material cache service
  await MaterialCacheService().init();
  
  runApp(
    const ProviderScope(
      child: ColetaneaDigitalApp(),
    ),
  );
}

class ColetaneaDigitalApp extends StatelessWidget {
  const ColetaneaDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Coletânea Digital',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Usar tema escuro por padrão (background marrom avermelhado)
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
