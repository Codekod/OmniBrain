import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AmbientTrack {
  final String id;
  final String name;
  final String icon;
  final String url;
  final bool isPro;

  const AmbientTrack({
    required this.id,
    required this.name,
    required this.icon,
    required this.url,
    required this.isPro,
  });
}

const List<AmbientTrack> ambientTracks = [
  AmbientTrack(
    id: 'rain',
    name: 'Yağmur',
    icon: '🌧️',
    url: 'https://cdn.freesound.org/previews/531/531947_11861866-lq.mp3',
    isPro: false, // Free for all users
  ),
  AmbientTrack(
    id: 'forest',
    name: 'Orman',
    icon: '🌲',
    url: 'https://cdn.freesound.org/previews/524/524312_11543324-lq.mp3',
    isPro: true, // PRO
  ),
  AmbientTrack(
    id: 'campfire',
    name: 'Şömine',
    icon: '🔥',
    url: 'https://cdn.freesound.org/previews/415/415209_5121236-lq.mp3',
    isPro: true, // PRO
  ),
  AmbientTrack(
    id: 'waves',
    name: 'Okyanus',
    icon: '🌊',
    url: 'https://cdn.freesound.org/previews/413/413749_7037-lq.mp3',
    isPro: true, // PRO
  ),
  AmbientTrack(
    id: 'whitenoise',
    name: 'Beyaz Gürültü',
    icon: '📻',
    url: 'https://cdn.freesound.org/previews/488/488388_10037320-lq.mp3',
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
    _player.setReleaseMode(ReleaseMode.loop);
    _player.setVolume(state.volume);
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
      await _player.setSourceUrl(track.url);
      await _player.resume();
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
