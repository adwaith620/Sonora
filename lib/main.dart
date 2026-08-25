import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants.dart';
import 'core/platform_utils.dart';
import 'data/providers/audio_provider.dart';
import 'navigation/app_router.dart';
import 'services/audio_handler.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Desktop window configuration
  if (isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        titleBarStyle: TitleBarStyle.hidden,
        minimumSize: Size(400, 600),
        size: Size(1100, 750),
        center: true,
        title: kAppName,
      ),
      () async {
        await windowManager.show();
      },
    );
  }

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final audioHandler = await AudioService.init(
    builder: () => SonoraAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.sonora.player.channel.audio',
      androidNotificationChannelName: 'Sonora Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidShowNotificationBadge: true,
      androidNotificationClickStartsActivity: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [audioHandlerProvider.overrideWithValue(audioHandler)],
      child: const SonoraApp(),
    ),
  );
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
