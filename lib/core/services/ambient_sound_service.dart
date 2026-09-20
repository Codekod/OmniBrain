import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AmbientTrack {
  final String id;
  final String name;
  final String icon;
  final String assetPath;
  final bool isPro;

  const AmbientTrack({
    required this.id,
    required this.name,
    required this.icon,
    required this.assetPath,
    required this.isPro,
  });
}

const List<AmbientTrack> ambientTracks = [
  AmbientTrack(
    id: 'rain',
    name: 'Yağmur',
    icon: '🌧️',
    assetPath: 'audio/rain.mp3',
    isPro: false, // Free for all users
  ),
  AmbientTrack(
    id: 'forest',
    name: 'Orman',
    icon: '🌲',
    assetPath: 'audio/forest.mp3',
    isPro: true, // PRO
  ),
  AmbientTrack(
    id: 'campfire',
    name: 'Şömine',
    icon: '🔥',
    assetPath: 'audio/campfire.mp3',
    isPro: true, // PRO
  ),
  AmbientTrack(
    id: 'waves',
    name: 'Okyanus',
    icon: '🌊',
    assetPath: 'audio/waves.mp3',
    isPro: true, // PRO
  ),
  AmbientTrack(
    id: 'whitenoise',
    name: 'Beyaz Gürültü',
    icon: '📻',
    assetPath: 'audio/whitenoise.mp3',
    isPro: true, // PRO
  ),
];

class AmbientSoundState {
  final String? activeTrackId;
  final bool isPlaying;
  final double volume;

  const AmbientSoundState({
    this.activeTrackId,
    this.isPlaying = false,
    this.volume = 0.7,
  });

  AmbientSoundState copyWith({
    String? activeTrackId,
    bool? isPlaying,
    double? volume,
    bool clearActiveTrack = false,
  }) {
    return AmbientSoundState(
      activeTrackId: clearActiveTrack ? null : (activeTrackId ?? this.activeTrackId),
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }
}

class AmbientSoundNotifier extends StateNotifier<AmbientSoundState> {
  final AudioPlayer _player = AudioPlayer();

  AmbientSoundNotifier() : super(const AmbientSoundState()) {
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(state.volume);
    } catch (_) {}
  }

  Future<void> toggleTrack(AmbientTrack track) async {
    if (state.activeTrackId == track.id && state.isPlaying) {
      await pause();
    } else {
      await play(track);
    }
  }

  Future<void> play(AmbientTrack track) async {
    try {
      state = state.copyWith(activeTrackId: track.id, isPlaying: true);
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(track.assetPath), volume: state.volume);
    } catch (e) {
      debugPrint('Error playing ambient sound: $e');
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      state = state.copyWith(isPlaying: false);
    } catch (e) {
      debugPrint('Error pausing ambient sound: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      state = state.copyWith(isPlaying: false, clearActiveTrack: true);
    } catch (e) {
      debugPrint('Error stopping ambient sound: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume);
    await _player.setVolume(volume);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final ambientSoundProvider = StateNotifierProvider<AmbientSoundNotifier, AmbientSoundState>((ref) {
  return AmbientSoundNotifier();
});
