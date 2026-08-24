import 'dart:io';

import 'package:saf/saf.dart';

abstract class MusicFileReference {
  String get uri;
  String get name;
  Future<int> getSize();

  /// Opens a random-access file, runs the callback, and guarantees cleanup.
  Future<T> withFile<T>(Future<T> Function(File file) action);
}

class WindowsMusicFileReference implements MusicFileReference {
  final File file;

  WindowsMusicFileReference(this.file);

  @override
  String get uri => file.path;

  @override
  String get name => file.path.split(Platform.pathSeparator).last;

  @override
  Future<int> getSize() async {
    final stat = await file.stat();
    return stat.size;
  }

  @override
  Future<T> withFile<T>(Future<T> Function(File file) action) async {
    return action(file);
  }
}

class AndroidSafMusicFileReference implements MusicFileReference {
  final SafDocumentFile safFile;
  final Saf _saf;

  AndroidSafMusicFileReference(this.safFile, this._saf);

  @override
  String get uri => safFile.uri;

  @override
  String get name => safFile.name;

  @override
  Future<int> getSize() async => safFile.length;

  @override
  Future<T> withFile<T>(Future<T> Function(File file) action) async {
    return _saf.withFileDescriptor(uri, 'r', (fd) async {
      final file = File(fd.path);
      return action(file);
    });
  }
}
