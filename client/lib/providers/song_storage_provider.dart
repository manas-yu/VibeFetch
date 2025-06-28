// songs_storage_provider.dart
import 'package:client/repository/socket_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Socket repository provider - add this if not imported from another file
final socketRepositoryProvider = Provider<SocketRepository>((ref) {
  return SocketRepository();
});

// State class for songs storage
class SongsStorageState {
  final List<String> ytIds;
  final bool isLoading;
  final String? error;

  const SongsStorageState({
    this.ytIds = const [],
    this.isLoading = false,
    this.error,
  });

  SongsStorageState copyWith({
    List<String>? ytIds,
    bool? isLoading,
    String? error,
  }) {
    return SongsStorageState(
      ytIds: ytIds ?? this.ytIds,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// StateNotifier for managing songs storage logic
class SongsStorageNotifier extends StateNotifier<SongsStorageState> {
  final SocketRepository _socketRepository;

  SongsStorageNotifier(this._socketRepository)
    : super(const SongsStorageState()) {
    _initializeSocketListeners();
    _loadYtIds();
  }

  void _initializeSocketListeners() {
    _socketRepository.listenYtIds(
      onYtIds: (ytIds) {
        state = state.copyWith(ytIds: ytIds, isLoading: false, error: null);
      },
    );
  }

  void _loadYtIds() {
    try {
      state = state.copyWith(isLoading: true, error: null);
      _socketRepository.getAllYTIds();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load YouTube IDs: ${e.toString()}',
      );
    }
  }

  void refreshYtIds() {
    _loadYtIds();
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  @override
  void dispose() {
    print('Disposing SongsStorageNotifier...');
    super.dispose();
  }
}

// Provider for songs storage
final songsStorageProvider =
    StateNotifierProvider<SongsStorageNotifier, SongsStorageState>((ref) {
      final socketRepository = ref.watch(socketRepositoryProvider);
      return SongsStorageNotifier(socketRepository);
    });

// Convenience providers for specific state properties
final ytIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(songsStorageProvider).ytIds;
});

final songsStorageLoadingProvider = Provider<bool>((ref) {
  return ref.watch(songsStorageProvider).isLoading;
});

final songsStorageErrorProvider = Provider<String?>((ref) {
  return ref.watch(songsStorageProvider).error;
});
