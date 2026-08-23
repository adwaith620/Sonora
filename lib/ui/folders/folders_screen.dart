import 'package:flutter/material.dart';

import '../common/empty_state.dart';

/// Folders screen — browse music by folder structure.
class FoldersScreen extends StatelessWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () {},
            tooltip: 'Add Folder',
          ),
        ],
      ),
      body: const EmptyState(
        icon: Icons.folder_outlined,
        title: 'No folders added',
        description: 'Add music folders to start building your library.',
      ),
    );
  }
}
