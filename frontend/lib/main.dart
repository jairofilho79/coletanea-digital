import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/material_cache_service.dart';
import 'core/storage/metadata_revalidation_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize background audio
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.coletaneadigital.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  
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
    return MetadataRevalidationBootstrap(
      child: MaterialApp.router(
        title: 'Coletânea Digital',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Usar tema escuro por padrão (background marrom avermelhado)
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
