import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/data/models/song.dart';
import 'package:sonora/data/providers/audio_provider.dart';
import 'package:sonora/services/audio_player_service.dart';
import 'package:sonora/ui/player/mini_player.dart';

class MockAudioPlayerService implements AudioPlayerService {
  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  PlaybackState _state = PlaybackState();

  void updateState(PlaybackState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  @override
  PlaybackState get currentState => _state;

  @override
  Stream<PlaybackState> get playbackStateStream => _stateController.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'MiniPlayer displays current song and reacts to playback changes',
    (WidgetTester tester) async {
      final mockService = MockAudioPlayerService();

      final song = const Song(
        id: '123',
        title: 'Test Song',
        artist: 'Test Artist',
        fileUri: 'file.mp3',
      );

      mockService.updateState(
        PlaybackState(currentSong: song, isPlaying: false),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioPlayerServiceProvider.overrideWithValue(mockService),
            playbackStateProvider.overrideWith(
              (ref) => mockService.currentState,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: MiniPlayer())),
        ),
      );

      await tester.pumpAndSettle();

      // It should display the song title and artist
      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);

      // Play icon should be visible
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    },
  );
}
