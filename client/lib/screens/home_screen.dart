import 'package:avatar_glow/avatar_glow.dart';
import 'package:client/screens/songs_storage.dart';
import 'package:client/widgets/animated_number.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/providers/music_recognition_provider.dart';
import 'package:client/widgets/match_list.dart';

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
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(next)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
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
        Color backgroundColor = const Color(0xFF1976D2);
        IconData icon = Icons.info;

        if (next.isError) {
          backgroundColor = Colors.red.shade700;
          icon = Icons.error;
        }
        if (next.isSuccess) {
          backgroundColor = Colors.green.shade700;
          icon = Icons.check_circle;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(next.message)),
              ],
            ),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    final hasMatches = musicState.matches.isNotEmpty;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF042442),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom App Bar
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // App Title with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF089af8), Color(0xFF4FC3F7)],
                      ).createShader(bounds),
                      child: const Text(
                        'VibeFetch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    // Songs counter with better styling
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const SongsStorage(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SlideTransition(
                                    position:
                                        Tween<Offset>(
                                          begin: const Offset(1.0, 0.0),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOut,
                                          ),
                                        ),
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF089af8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.library_music,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedNumber(
                              value: musicState.totalSongs,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Songs',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            SliverToBoxAdapter(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: hasMatches ? 0 : screenHeight * 0.7,
                ),
                child: hasMatches
                    ? _buildMatchesView(musicState)
                    : _buildListeningView(context, musicState, musicNotifier),
              ),
            ),
          ],
        ),
      ),

      // Improved FAB
      floatingActionButton: _buildFloatingActionButton(
        context,
        musicState,
        musicNotifier,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMatchesView(MusicRecognitionState musicState) {
    return Column(
      children: [
        const SizedBox(height: 20),
        MatchListWidget(matches: musicState.matches),
        const SizedBox(height: 100), // Space for FAB
      ],
    );
  }

  Widget _buildListeningView(
    BuildContext context,
    MusicRecognitionState musicState,
    MusicRecognitionNotifier musicNotifier,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Status text with better styling
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _getStatusText(musicState),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 50),

        // Enhanced listen button
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow effect
            if (musicState.isListening)
              AvatarGlow(
                animate: true,
                glowColor: const Color(0xFF089af8),
                duration: const Duration(milliseconds: 2000),
                child: Container(
                  height: 220,
                  width: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                ),
              ),

            // Main button
            GestureDetector(
              onTap: () => _handleRecognitionTap(musicNotifier, musicState),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _getButtonGradient(musicState),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getButtonColor(musicState).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(child: _buildButtonContent(musicState)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // Cancel button with better styling
        if (musicState.isListening)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: TextButton(
              onPressed: () {
                musicNotifier.cancelRecognition();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stop, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Cancel Recording',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    MusicRecognitionState musicState,
    MusicRecognitionNotifier musicNotifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton.extended(
        onPressed: musicState.isLoading
            ? null
            : () => _showAddSongDialog(
                context,
                musicNotifier,
                musicState.isLoading,
              ),
        backgroundColor: musicState.isLoading
            ? Colors.grey.shade600
            : const Color(0xFF089af8),
        elevation: 8,
        icon: musicState.isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.7),
                  ),
                ),
              )
            : const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text(
          'Add Song',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
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
    } else if (!state.isLoading) {
      notifier.startRecognition();
    }
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
          backgroundColor: const Color(0xFF0A1628),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF089af8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Add Spotify Song',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://open.spotify.com/track/...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  prefixIcon: Icon(
                    Icons.link,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF089af8),
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
                maxLines: 2,
              ),

              if (isLoading) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF089af8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Adding song to library...',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      final url = urlController.text.trim();
                      if (url.isEmpty) {
                        _showErrorSnackBar(context, 'Please enter a URL');
                        return;
                      }

                      if (!url.contains('spotify')) {
                        _showErrorSnackBar(
                          context,
                          'Please enter a valid Spotify URL',
                        );
                        return;
                      }

                      notifier.downloadSong(url);
                      Navigator.of(context).pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF089af8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add Song',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getStatusText(MusicRecognitionState state) {
    if (state.isListening) {
      return 'Listening for music...\nRecording will auto-stop in 20 seconds';
    } else if (state.isLoading) {
      return 'Processing your audio...\nThis may take a moment';
    } else if (state.error != null) {
      return 'Ready to listen again\nTap the button to try once more';
    } else {
      return 'Tap the button below\nto start listening for music';
    }
  }

  List<Color> _getButtonGradient(MusicRecognitionState state) {
    if (state.isLoading) {
      return [
        const Color(0xFF089af8).withOpacity(0.7),
        const Color(0xFF4FC3F7).withOpacity(0.7),
      ];
    } else if (state.isListening) {
      return [Colors.red.shade500, Colors.red.shade700];
    } else {
      return [const Color(0xFF089af8), const Color(0xFF4FC3F7)];
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
      return const Icon(Icons.stop, color: Colors.white, size: 45);
    } else {
      return const Icon(Icons.mic, color: Colors.white, size: 45);
    }
  }
}
