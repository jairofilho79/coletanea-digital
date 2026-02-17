import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'coldigom_client.dart';
import 'coletanea_client.dart';

/// Provider for ColdigomClient (read-only API)
final coldigomClientProvider = Provider<ColdigomClient>((ref) {
  return ColdigomClient();
});

/// Provider for ColetaneaClient (own backend API)
final coletaneaClientProvider = Provider<ColetaneaClient>((ref) {
  return ColetaneaClient();
});
