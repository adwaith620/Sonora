import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants.dart';
import 'core/platform_utils.dart';
import 'navigation/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop window configuration
  if (isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.setTitle(kAppName);
    await windowManager.setMinimumSize(const Size(400, 600));
    await windowManager.setSize(const Size(1100, 750));
    await windowManager.center();
    await windowManager.show();
  }

  runApp(const ProviderScope(child: SonoraApp()));
}

/// Root application widget.
class SonoraApp extends ConsumerWidget {
  const SonoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createRouter();
    final themeMode = ref.watch(themeModeProvider);
    final seedColor = ref.watch(seedColorProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: kAppName,
          debugShowCheckedModeBanner: false,
          routerConfig: router,

          // Light theme
          theme: createSonoraTheme(
            brightness: Brightness.light,
            dynamicScheme: lightDynamic,
            seedColor: seedColor,
          ),

          // Dark theme
          darkTheme: createSonoraTheme(
            brightness: Brightness.dark,
            dynamicScheme: darkDynamic,
            seedColor: seedColor,
            oled: themeMode == SonoraThemeMode.oled,
          ),

          // Theme mode
          themeMode: switch (themeMode) {
            SonoraThemeMode.system => ThemeMode.system,
            SonoraThemeMode.light => ThemeMode.light,
            SonoraThemeMode.dark => ThemeMode.dark,
            SonoraThemeMode.oled => ThemeMode.dark,
          },
        );
      },
    );
  }
}
