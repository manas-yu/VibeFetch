// screens/home_screen.dart
import 'package:avatar_glow/avatar_glow.dart';
import 'package:client/widgets/animated_number.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/providers/music_recognition_provider.dart';
import 'package:client/widgets/match_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicState = ref.watch(musicRecognitionProvider);
    final musicNotifier = ref.watch(musicRecognitionProvider.notifier);

    // Show error if any
    ref.listen(errorProvider, (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        // Clear error after showing
        Future.delayed(const Duration(milliseconds: 100), () {
          musicNotifier.clearError();
        });
      }
    });

    // Show download status messages
    ref.listen(musicRecognitionProvider.select((state) => state.lastStatus), (
      previous,
      next,
    ) {
      if (next != null) {
        Color backgroundColor = Colors.blue;
        if (next.isError) backgroundColor = Colors.red;
        if (next.isSuccess) backgroundColor = Colors.green;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: musicState.isLoading
            ? null
            : () {
                _showAddSongDialog(
                  context,
                  musicNotifier,
                  musicState.isLoading,
                );
              },
        backgroundColor: musicState.isLoading
            ? Colors.blueGrey.shade700
            : const Color.fromARGB(255, 70, 156, 166), // Bright on dark blue
        elevation: 6,
        tooltip: 'Add Song',
        child: musicState.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              )
            : const Icon(Icons.add, size: 28, color: Colors.black87),
      ),

      backgroundColor: const Color(0xFF042442),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'VibeFetch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.music_note,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              AnimatedNumber(
                                value: musicState.totalSongs,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Songs',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 100),
              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status text
                  Text(
                    _getStatusText(musicState),
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Listen button with improved interaction
                  AvatarGlow(
                    animate: musicState.isListening,
                    glowColor: const Color(0xFF089af8),
                    duration: const Duration(milliseconds: 2000),
                    child: GestureDetector(
                      onTap: () =>
                          _handleRecognitionTap(musicNotifier, musicState),
                      child: Material(
                        elevation: 8,
                        shape: const CircleBorder(),
                        color: _getButtonColor(musicState),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getButtonColor(musicState),
                          ),
                          child: Center(child: _buildButtonContent(musicState)),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cancel button (only show when listening)
                  if (musicState.isListening)
                    TextButton(
                      onPressed: () {
                        musicNotifier.cancelRecognition();
                        print('Cancelling recognition');
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),

              // Matches section - fixed layout issue
              if (musicState.matches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Matches (${musicState.matches.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                musicNotifier.clearMatches();
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: musicState.matches.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: MatchCard(match: musicState.matches[index]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRecognitionTap(
    MusicRecognitionNotifier notifier,
    MusicRecognitionState state,
  ) {
    if (state.isListening) {
      notifier.stopRecognition();
      print('Manually stopping recognition');
    } else if (!state.isLoading) {
      notifier.startRecognition();
      print('Starting recognition');
    }
    // If isLoading, do nothing (button is effectively disabled)
  }

  void _showAddSongDialog(
    BuildContext context,
    MusicRecognitionNotifier notifier,
    bool isLoading,
  ) {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1B2A), // deep dark blue
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Spotify Song',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste Spotify URL',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.cyanAccent,
                      width: 2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
                autofocus: true,
                enabled: !isLoading,
                maxLines: 1,
              ),

              if (isLoading) ...[
                const SizedBox(height: 20),
                Row(
                  children: const [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.cyanAccent,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Adding song...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      final url = urlController.text.trim();
                      if (url.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a URL'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (!url.contains('spotify')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid Spotify URL'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      notifier.downloadSong(url);
                      Navigator.of(context).pop();
                    },
              style: TextButton.styleFrom(foregroundColor: Colors.cyanAccent),
              child: const Text('Add Song'),
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(MusicRecognitionState state) {
    if (state.isListening) {
      return 'Listening...\n(Recording will auto-stop in 20 seconds)';
    } else if (state.isLoading) {
      return 'Processing audio...\nPlease wait';
    } else if (state.matches.isNotEmpty) {
      return 'Found ${state.matches.length} match(es)!';
    } else if (state.error != null) {
      return 'Ready to listen\n(Tap the button to try again)';
    } else {
      return 'Tap to start listening\nfor music';
    }
  }

  Color _getButtonColor(MusicRecognitionState state) {
    if (state.isLoading) {
      return const Color(0xFF089af8).withOpacity(0.7);
    } else if (state.isListening) {
      return Colors.red;
    } else {
      return const Color(0xFF089af8);
    }
  }

  Widget _buildButtonContent(MusicRecognitionState state) {
    if (state.isLoading) {
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 3,
      );
    } else if (state.isListening) {
      return const Icon(Icons.stop, color: Colors.white, size: 40);
    } else {
      return const Icon(Icons.mic, color: Colors.white, size: 40);
    }
  }
}
