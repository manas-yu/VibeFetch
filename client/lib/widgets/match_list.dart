import 'package:client/models/match_model.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MatchListWidget extends StatefulWidget {
  final List<MatchModel> matches;

  const MatchListWidget({super.key, required this.matches});

  @override
  State<MatchListWidget> createState() => _MatchListWidgetState();
}

class _MatchListWidgetState extends State<MatchListWidget> {
  Map<int, YoutubePlayerController> controllers = {};
  Map<int, bool> expandedStates = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each match
    for (var match in widget.matches) {
      print("Initializing controller for match: ${match.songId}");
      print(match.toJson());
      controllers[match.songId] = YoutubePlayerController(
        initialVideoId: match.youtubeId,
        flags: YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          startAt: match.timestamp,
        ),
      );
      expandedStates[match.songId] = false;
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String formatDuration(int seconds) {
    Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  Color getScoreColor(double score) {
    if (score >= 0.35) return const Color(0xFF4CAF50); // Green
    if (score >= 0.25) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Icon(Icons.music_note, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Song Matches (${widget.matches.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // List of matches
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.matches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final match = widget.matches[index];
              final controller = controllers[match.songId]!;
              final isExpanded = expandedStates[match.songId] ?? false;

              return Container(
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF0A1628,
                  ), // Slightly lighter than scaffold
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Main content - always visible
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Song Info Header
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      match.songTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      match.songArtist,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: getScoreColor(match.score),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(match.score * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Timestamp and expand button
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Starts at: ${formatDuration(match.timestamp)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    expandedStates[match.songId] = !isExpanded;
                                  });
                                },
                                icon: Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: const Color(0xFF089af8),
                                  size: 20,
                                ),
                                label: Text(
                                  isExpanded ? 'Less' : 'Play',
                                  style: const TextStyle(
                                    color: Color(0xFF089af8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Expandable YouTube player section
                    if (isExpanded) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // YouTube Player
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: YoutubePlayer(
                                  controller: controller,
                                  showVideoProgressIndicator: true,
                                  progressIndicatorColor: const Color(
                                    0xFF089af8,
                                  ),
                                  progressColors: const ProgressBarColors(
                                    playedColor: Color(0xFF089af8),
                                    handleColor: Color(0xFF089af8),
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white12,
                                  ),
                                  onReady: () {
                                    controller.seekTo(
                                      Duration(seconds: match.timestamp),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      controller.seekTo(
                                        Duration(seconds: match.timestamp),
                                      );
                                      controller.play();
                                    },
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 18,
                                    ),
                                    label: const Text('Play from Match'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF089af8),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      controller.seekTo(
                                        const Duration(seconds: 0),
                                      );
                                    },
                                    icon: const Icon(Icons.replay, size: 18),
                                    label: const Text('Start Over'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }
}
