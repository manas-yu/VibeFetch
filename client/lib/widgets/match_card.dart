// widgets/match_card.dart
import 'package:client/models/match_model.dart';
import 'package:flutter/material.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: match.thumbnailUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  match.thumbnailUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note),
                    );
                  },
                ),
              )
            : Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.music_note),
              ),
        title: Text(
          match.title ?? 'Unknown Title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(match.artist ?? 'Unknown Artist'),
            if (match.confidence != null)
              Text(
                'Confidence: ${(match.confidence! * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (match.youtubeUrl != null)
              IconButton(
                icon: const Icon(Icons.play_circle_fill, color: Colors.red),
                onPressed: () {
                  // TODO: Open YouTube URL
                },
              ),
            if (match.spotifyUrl != null)
              IconButton(
                icon: const Icon(Icons.music_note, color: Colors.green),
                onPressed: () {
                  // TODO: Open Spotify URL
                },
              ),
          ],
        ),
      ),
    );
  }
}
