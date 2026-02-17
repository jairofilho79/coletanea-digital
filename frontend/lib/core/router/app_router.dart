import 'package:go_router/go_router.dart';
import '../widgets/app_shell.dart';
import '../../features/praises/presentation/pages/praises_list_page.dart';
import '../../features/praises/presentation/pages/praise_detail_page.dart';
import '../../features/listas/presentation/pages/listas_page.dart';
import '../../features/listas/presentation/pages/lista_detail_page.dart';
import '../../features/salas/presentation/pages/salas_page.dart';
import '../../features/salas/presentation/pages/sala_detail_page.dart';
import '../../features/reader/presentation/pages/pdf_reader_page.dart';
import '../../features/reader/presentation/pages/audio_reader_page.dart';
import '../../features/reader/presentation/pages/lyrics_reader_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => PraisesListPage(
            addToListaId: state.uri.queryParameters['addToLista'],
            addToSala: state.uri.queryParameters['addToSala'],
          ),
        ),
        GoRoute(
          path: '/praises',
          name: 'praises',
          builder: (context, state) => PraisesListPage(
            addToListaId: state.uri.queryParameters['addToLista'],
            addToSala: state.uri.queryParameters['addToSala'],
          ),
        ),
        GoRoute(
          path: '/praises/:praiseId',
          name: 'praise_detail',
          builder: (context, state) {
            final praiseId = state.pathParameters['praiseId']!;
            final salaId = state.uri.queryParameters['salaId'];
            return PraiseDetailPage(praiseId: praiseId, salaId: salaId);
          },
        ),
        GoRoute(
          path: '/listas',
          name: 'listas',
          builder: (context, state) => const ListasPage(),
          routes: [
            GoRoute(
              path: ':listaId',
              name: 'lista_detail',
              builder: (context, state) {
                final listaId = state.pathParameters['listaId']!;
                return ListaDetailPage(listaId: listaId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/salas',
          name: 'salas',
          builder: (context, state) => const SalasPage(),
          routes: [
            GoRoute(
              path: ':salaId',
              name: 'sala_detail',
              builder: (context, state) {
                final salaId = state.pathParameters['salaId']!;
                return SalaDetailPage(salaId: salaId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/reader/pdf/:materialId',
          name: 'pdf_reader',
          builder: (context, state) {
            final materialId = state.pathParameters['materialId']!;
            final materialPath = state.uri.queryParameters['path'] ?? '';
            final materialName = state.uri.queryParameters['name'];
            final salaId = state.uri.queryParameters['salaId'];
            final participanteId = state.uri.queryParameters['participanteId'];
            final materialIndex = state.uri.queryParameters['materialIndex'];
            return PdfReaderPage(
              materialId: materialId,
              materialPath: materialPath,
              materialName: materialName,
              salaId: salaId,
              participanteId: participanteId,
              materialIndex: materialIndex != null ? int.tryParse(materialIndex) : null,
            );
          },
        ),
        GoRoute(
          path: '/reader/audio/:materialId',
          name: 'audio_reader',
          builder: (context, state) {
            final materialId = state.pathParameters['materialId']!;
            final materialPath = state.uri.queryParameters['path'] ?? '';
            final materialName = state.uri.queryParameters['name'];
            final praiseName = state.uri.queryParameters['praiseName'];
            final materialKindName = state.uri.queryParameters['materialKindName'];
            return AudioReaderPage(
              materialId: materialId,
              materialPath: materialPath,
              materialName: materialName,
              praiseName: praiseName,
              materialKindName: materialKindName,
            );
          },
        ),
        GoRoute(
          path: '/reader/lyrics/:materialId',
          name: 'lyrics_reader',
          builder: (context, state) {
            final materialId = state.pathParameters['materialId']!;
            final materialPath = state.uri.queryParameters['path'] ?? '';
            final materialName = state.uri.queryParameters['name'];
            final salaId = state.uri.queryParameters['salaId'];
            final participanteId = state.uri.queryParameters['participanteId'];
            final materialIndex = state.uri.queryParameters['materialIndex'];
            return LyricsReaderPage(
              materialId: materialId,
              materialPath: materialPath,
              materialName: materialName,
              salaId: salaId,
              participanteId: participanteId,
              materialIndex: materialIndex != null ? int.tryParse(materialIndex) : null,
            );
          },
        ),
      ],
    ),
  ],
);
