import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/data/providers/scanner_provider.dart';
import 'package:sonora/services/scanner_service.dart';
import 'package:sonora/theme/app_theme.dart';
import 'package:sonora/ui/settings/settings_screen.dart';

class MockScannerService implements ScannerService {
  @override
  Stream<ScannerState> get stateStream => const Stream.empty();

  @override
  ScannerState get currentState => const ScannerState();

  @override
  Future<void> scanLibrary() async {}

  @override
  void cancelScan() {}

  @override
  Future<void> addFolder(String path) async {}

  @override
  Future<void> removeFolder(String path) async {}

  @override
  Future<List<String>> getEnabledFolders() async => [];
}

void main() {
  testWidgets('Settings screen theme changes work', (
    WidgetTester tester,
  ) async {
    final mockScanner = MockScannerService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [scannerServiceProvider.overrideWithValue(mockScanner)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    // Initial state is system theme
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('OLED Black'), findsOneWidget);

    // Tap on Dark theme
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Verify Riverpod state updated (we can verify indirectly by the tap succeeding without errors,
    // but better yet we could watch the provider).

    final radioWidgets = tester
        .widgetList<RadioListTile<SonoraThemeMode>>(
          find.byType(RadioListTile<SonoraThemeMode>),
        )
        .toList();

    // We selected dark theme, let's verify if the group value for Dark theme became Dark
    final darkRadio = radioWidgets.firstWhere(
      (r) => r.value == SonoraThemeMode.dark,
    );
    expect(darkRadio.groupValue, SonoraThemeMode.dark);
  });
}
