import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'changelog_api.dart';
import 'coldigom_client.dart';
import 'coletanea_client.dart';

/// Provider for ColdigomClient (read-only API)
final coldigomClientProvider = Provider<ColdigomClient>((ref) {
  return ColdigomClient();
});

/// Provider for ChangelogApi (version + changelog delta)
final changelogApiProvider = Provider<ChangelogApi>((ref) {
  return ChangelogApi(ref.watch(coldigomClientProvider));
});

/// Provider for ColetaneaClient (own backend API)
final coletaneaClientProvider = Provider<ColetaneaClient>((ref) {
  return ColetaneaClient();
});
