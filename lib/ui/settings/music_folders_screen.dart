import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saf/saf.dart';

import '../../data/providers/repository_providers.dart';
import '../../data/providers/scanner_provider.dart';
import '../../services/scanner_service.dart';

class MusicFoldersScreen extends ConsumerStatefulWidget {
  const MusicFoldersScreen({super.key});

  @override
  ConsumerState<MusicFoldersScreen> createState() => _MusicFoldersScreenState();
}

class _MusicFoldersScreenState extends ConsumerState<MusicFoldersScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final scannerState = ref.watch(scannerStateProvider);
    final isScanning = scannerState.value?.status == ScannerStatus.scanning;

    return Scaffold(
      appBar: AppBar(title: const Text('Music Folders')),
      body: FutureBuilder(
        future: db.libraryDao.getLibraryLocations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final locations = snapshot.data!;

          if (locations.isEmpty) {
            return const Center(child: Text('No music folders added.'));
          }

          return ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final loc = locations[index];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(loc.folderUri),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: isScanning
                      ? null
                      : () async {
                          await db.libraryDao.removeLibraryLocation(
                            loc.folderUri,
                          );
                          if (Platform.isAndroid && loc.folderUri.startsWith('content://')) {
                            // Release the persisted SAF permission
                            await Saf().releasePersistedPermission(loc.folderUri);
                          }
                          setState(() {});
                        },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isScanning
            ? null
            : () async {
                String? newUri;
                if (Platform.isAndroid) {
                  final saf = Saf();
                  final dir = await saf.pickDirectory(persistablePermission: true);
                  newUri = dir?.uri;
                } else {
                  newUri = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: 'Select Music Folder',
                  );
                }

                if (newUri != null) {
                  await db.libraryDao.addLibraryLocation(newUri);
                  setState(() {});
                  // Optional: Auto start scan when a new folder is added
                  ref.read(scannerServiceProvider).scanLibrary();
                }
              },
        icon: const Icon(Icons.add),
        label: const Text('Add Folder'),
      ),
    );
  }
}
