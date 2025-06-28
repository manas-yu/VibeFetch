import 'package:client/models/download_status.dart';
import 'package:client/models/fingerprint_data.dart';
import 'package:client/models/recording_data.dart';
import 'package:client/repository/socket_repository.dart';
import 'package:client/services/fingerprint_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/services/audio_service.dart';

// State class for music recognition
class MusicRecognitionState {
  final bool isListening;
  final String? match;
  final int totalSongs;
  final bool isLoading;
  final String? error;
  final DownloadStatusModel? lastStatus;

  const MusicRecognitionState({
    this.isListening = false,
    this.match,
    this.totalSongs = 0,
    this.isLoading = false,
    this.error,
    this.lastStatus,
  });

  MusicRecognitionState copyWith({
    bool? isListening,
    String? match,
    int? totalSongs,
    bool? isLoading,
    String? error,
    DownloadStatusModel? lastStatus,
  }) {
    return MusicRecognitionState(
      isListening: isListening ?? this.isListening,
      match: match ?? this.match,
      totalSongs: totalSongs ?? this.totalSongs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }
}

// StateNotifier for managing music recognition logic
class MusicRecognitionNotifier extends StateNotifier<MusicRecognitionState> {
  final SocketRepository _socketRepository;
  final AudioService _audioService;
  final FingerprintService _fingerprintService;

  MusicRecognitionNotifier(
    this._socketRepository,
    this._audioService,
    this._fingerprintService,
  ) : super(const MusicRecognitionState()) {
    _initializeSocketListeners();
    _requestTotalSongs();
  }

  void _initializeSocketListeners() {
    _socketRepository.initializeListeners(
      onMatches: (match) {
        if (match.isEmpty) {
          print('No matches found');
          state = state.copyWith(
            isLoading: false,
            isListening: false,
            error: 'No matches found',
          );
          return;
        }
        state = state.copyWith(
          match: match,
          isLoading: false,
          isListening: false,
        );
      },
      onDownloadStatus: (status) {
        state = state.copyWith(lastStatus: status);
      },
      onTotalSongs: (totalSongs) {
        state = state.copyWith(totalSongs: totalSongs);
      },
    );
  }

  void _requestTotalSongs() {
    _socketRepository.requestTotalSongs();
  }

  Future<void> downloadSong(String url) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      _socketRepository.addSongFromUrl(url: url);
      _socketRepository.requestTotalSongs();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to download song: ${e.toString()}',
      );
    }
  }

  Future<void> startRecognition() async {
    try {
      // Prevent starting if already listening or loading
      if (state.isListening || state.isLoading) {
        print('Recognition already in progress, ignoring start request');
        return;
      }

      state = state.copyWith(
        isListening: true,
        isLoading: false,
        error: null,
        match: null,
      );

      // Start microphone recording with auto-stop callback
      await _audioService.startRecording(
        durationSeconds: 20,
        onAutoStop: () {
          // This will be called when the timer expires
          print('Auto-stop triggered, calling stopRecognition');
          stopRecognition();
        },
      );

      print('Microphone recording started successfully');
    } catch (e) {
      print('Error starting recognition: $e');
      state = state.copyWith(
        isListening: false,
        isLoading: false,
        error: 'Failed to start recording: ${e.toString()}',
      );
    }
  }

  Future<void> stopRecognition() async {
    try {
      // Prevent multiple stop calls
      if (!state.isListening && !state.isLoading) {
        print('Not currently listening or processing, ignoring stop request');
        return;
      }

      print('Stopping recognition...');

      // Update state to show we're processing
      state = state.copyWith(isListening: false, isLoading: true, error: null);

      // Stop recording
      final recordingPath = await _audioService.stopRecording();

      print('Microphone recording stopped, file path: $recordingPath');

      if (recordingPath != null && recordingPath.isNotEmpty) {
        print('Processing microphone recording at: $recordingPath');
        await _processRecording(recordingPath);
      } else {
        throw Exception('Failed to get valid recording path');
      }
    } catch (e) {
      print('Error stopping recognition: $e');
      state = state.copyWith(
        isListening: false,
        isLoading: false,
        error: 'Failed to stop recording: ${e.toString()}',
      );
    }
  }

  Future<void> cancelRecognition() async {
    try {
      print('Cancelling recognition...');

      // Cancel the recording without processing
      await _audioService.cancelRecording();

      state = state.copyWith(isListening: false, isLoading: false, error: null);

      print('Recognition cancelled successfully');
    } catch (e) {
      print('Error cancelling recognition: $e');
      state = state.copyWith(
        isListening: false,
        isLoading: false,
        error: 'Failed to cancel recording: ${e.toString()}',
      );
    }
  }

  Future<void> _processRecording(String filePath) async {
    try {
      print('Processing recording at: $filePath');

      // Verify file exists and is valid
      final metadata = await _audioService.getAudioMetadata(filePath);
      print('Audio metadata: $metadata');

      // Check if recording is long enough (at least 1 second)
      if (metadata['duration'] < 1.0) {
        throw Exception('Recording too short: ${metadata['duration']} seconds');
      }

      // Convert to base64
      final audioBase64 = await _audioService.audioFileToBase64(filePath);
      print('Audio converted to base64, length: ${audioBase64.length}');

      // Create record data model
      final recordData = RecordDataModel(
        audio: audioBase64,
        channels: metadata['channels'],
        sampleRate: metadata['sampleRate'],
        sampleSize: metadata['sampleSize'],
        duration: metadata['duration'],
      );

      // Send recording to backend
      print('Sending recording data to backend...');
      _socketRepository.sendRecording(recordData);

      // Generate fingerprint
      print('Generating fingerprint...');
      final fingerprintResult = await _fingerprintService.generateFingerprint(
        filePath,
      );
      print('Fingerprint result: $fingerprintResult');

      if (fingerprintResult['error'] == 0) {
        final fingerprints = (fingerprintResult['data'] as List)
            .map((json) => FingerprintModel.fromJson(json))
            .toList();

        if (fingerprints.isEmpty) {
          throw Exception('No fingerprints generated from audio');
        }

        // Format for backend
        final fingerprintMap = _fingerprintService.formatFingerprintForBackend(
          fingerprints,
        );
        print('Fingerprint data formatted: ${fingerprintMap.toString()}');

        // Send to backend
        print('Sending fingerprint to backend...');
        _socketRepository.sendFingerprint(fingerprintMap);

        // !Will wait infinitely for matches from socket
        // Update state - processing complete, waiting for results
        state = state.copyWith(
          isLoading: true, // Keep loading until we get matches from socket
          isListening: false,
          error: null,
        );

        print('Processing completed successfully, waiting for matches...');
      } else {
        final errorMessage =
            fingerprintResult['message'] ?? 'Unknown fingerprint error';
        throw Exception('Fingerprint generation failed: $errorMessage');
      }
    } catch (e) {
      print('Error processing recording: $e');
      state = state.copyWith(
        isLoading: false,
        isListening: false,
        error: 'Failed to process recording: ${e.toString()}',
      );
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  void clearMatch() {
    if (state.match != null) {
      state = state.copyWith(match: null);
    }
  }

  // Helper method to check current status
  bool get canStartRecognition => !state.isListening && !state.isLoading;
  bool get canStopRecognition => state.isListening;
  bool get isProcessing => state.isLoading;

  @override
  void dispose() {
    print('Disposing MusicRecognitionNotifier...');
    _audioService.dispose();
    _socketRepository.dispose();
    super.dispose();
  }
}

// Providers remain the same
final socketRepositoryProvider = Provider<SocketRepository>((ref) {
  return SocketRepository();
});

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

final fingerprintServiceProvider = Provider<FingerprintService>((ref) {
  return FingerprintService();
});

final musicRecognitionProvider =
    StateNotifierProvider<MusicRecognitionNotifier, MusicRecognitionState>((
      ref,
    ) {
      final socketRepository = ref.watch(socketRepositoryProvider);
      final audioService = ref.watch(audioServiceProvider);
      final fingerprintService = ref.watch(fingerprintServiceProvider);
      return MusicRecognitionNotifier(
        socketRepository,
        audioService,
        fingerprintService,
      );
    });

// Convenience providers for specific state properties
final isListeningProvider = Provider<bool>((ref) {
  return ref.watch(musicRecognitionProvider).isListening;
});

final matchProvider = Provider<String?>((ref) {
  return ref.watch(musicRecognitionProvider).match;
});

final totalSongsProvider = Provider<int>((ref) {
  return ref.watch(musicRecognitionProvider).totalSongs;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(musicRecognitionProvider).isLoading;
});

final errorProvider = Provider<String?>((ref) {
  return ref.watch(musicRecognitionProvider).error;
});

// Additional convenience providers
final canStartRecognitionProvider = Provider<bool>((ref) {
  return ref.watch(musicRecognitionProvider.notifier).canStartRecognition;
});

final canStopRecognitionProvider = Provider<bool>((ref) {
  return ref.watch(musicRecognitionProvider.notifier).canStopRecognition;
});

final isProcessingProvider = Provider<bool>((ref) {
  return ref.watch(musicRecognitionProvider.notifier).isProcessing;
});
