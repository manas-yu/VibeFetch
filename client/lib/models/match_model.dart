class MatchModel {
  final int songId;
  final String songTitle;
  final String songArtist;
  final String youtubeId;
  final int timestamp;
  final double score;

  MatchModel({
    required this.songId,
    required this.songTitle,
    required this.songArtist,
    required this.youtubeId,
    required this.timestamp,
    required this.score,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MatchModel(
      songId: parseInt(json['SongID'] ?? json['song_id']),
      songTitle: json['SongTitle'] ?? json['song_title'] ?? '',
      songArtist: json['SongArtist'] ?? json['song_artist'] ?? '',
      youtubeId: json['YouTubeID'] ?? json['youtube_id'] ?? '',
      timestamp: parseInt(json['Timestamp'] ?? json['timestamp']),
      score: parseDouble(json['Score'] ?? json['score']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'song_id': songId,
      'song_title': songTitle,
      'song_artist': songArtist,
      'youtube_id': youtubeId,
      'timestamp': timestamp,
      'score': score,
    };
  }
}
