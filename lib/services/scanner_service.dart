enum ScannerStatus { idle, scanning, cancelling, error }

class ScannerState {
  final ScannerStatus status;
  final int filesDiscovered;
  final int filesProcessed;
  final int filesAdded;
  final int filesUpdated;
  final int filesRemoved;
  final String? currentFile;
  final String? errorMessage;

  const ScannerState({
    this.status = ScannerStatus.idle,
    this.filesDiscovered = 0,
    this.filesProcessed = 0,
    this.filesAdded = 0,
    this.filesUpdated = 0,
    this.filesRemoved = 0,
    this.currentFile,
    this.errorMessage,
  });

  ScannerState copyWith({
    ScannerStatus? status,
    int? filesDiscovered,
    int? filesProcessed,
    int? filesAdded,
    int? filesUpdated,
    int? filesRemoved,
    String? currentFile,
    String? errorMessage,
  }) {
    return ScannerState(
      status: status ?? this.status,
      filesDiscovered: filesDiscovered ?? this.filesDiscovered,
      filesProcessed: filesProcessed ?? this.filesProcessed,
      filesAdded: filesAdded ?? this.filesAdded,
      filesUpdated: filesUpdated ?? this.filesUpdated,
      filesRemoved: filesRemoved ?? this.filesRemoved,
      currentFile: currentFile ?? this.currentFile,
      errorMessage: errorMessage,
    );
  }
}

abstract class ScannerService {
  /// Stream of current scan state
  Stream<ScannerState> get stateStream;

  /// Get current state
  ScannerState get currentState;

  /// Trigger a library scan on configured folders
  Future<void> scanLibrary();

  /// Cancel an ongoing scan
  void cancelScan();
}
