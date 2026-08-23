import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/providers/scanner_provider.dart';
import '../../services/scanner_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/dimensions.dart';
import '../../theme/theme_provider.dart';
import 'music_folders_screen.dart';

/// Settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance section
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Text(
              'Appearance',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          // ignore: deprecated_member_use
          RadioListTile<SonoraThemeMode>(
            title: const Text('System'),
            subtitle: const Text('Follow system theme'),
            value: SonoraThemeMode.system,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          // ignore: deprecated_member_use
          RadioListTile<SonoraThemeMode>(
            title: const Text('Light'),
            value: SonoraThemeMode.light,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          // ignore: deprecated_member_use
          RadioListTile<SonoraThemeMode>(
            title: const Text('Dark'),
            value: SonoraThemeMode.dark,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          // ignore: deprecated_member_use
          RadioListTile<SonoraThemeMode>(
            title: const Text('OLED Black'),
            subtitle: const Text('Pure black for AMOLED displays'),
            value: SonoraThemeMode.oled,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),

          const Divider(),

          // Library section
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Text(
              'Library',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Music Folders'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MusicFoldersScreen()),
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final scanState = ref.watch(scannerStateProvider);
              final isScanning =
                  scanState.value?.status == ScannerStatus.scanning;

              return ListTile(
                leading: isScanning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                title: Text(isScanning ? 'Scanning...' : 'Rescan Library'),
                subtitle: isScanning
                    ? Text(
                        'Found ${scanState.value?.filesDiscovered ?? 0} files...',
                      )
                    : const Text('Scan for new and changed files'),
                onTap: isScanning
                    ? () => ref.read(scannerServiceProvider).cancelScan()
                    : () => ref.read(scannerServiceProvider).scanLibrary(),
              );
            },
          ),

          const Divider(),

          // About section
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Text(
              'About',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: const Text(kAppName),
            subtitle: const Text('Version $kAppVersion'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
