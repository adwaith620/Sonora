import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/local_scanner_service.dart';
import '../../services/scanner_service.dart';
import 'repository_providers.dart';

final scannerServiceProvider = Provider<ScannerService>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalScannerService(db);
});

final scannerStateProvider = StreamProvider<ScannerState>((ref) {
  final service = ref.watch(scannerServiceProvider);
  return service.stateStream;
});

final currentScannerStateProvider = Provider<ScannerState>((ref) {
  final asyncState = ref.watch(scannerStateProvider);
  return asyncState.value ?? const ScannerState();
});
