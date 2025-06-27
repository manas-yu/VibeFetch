class MatchModel {
  final String? title;
  final String? artist;
  final String? album;
  final String? youtubeUrl;
  final String? thumbnailUrl;
  final double? confidence;
  final int? offsetSeconds;
  final String? spotifyUrl;
  final String? appleMusicUrl;

  MatchModel({
    this.title,
    this.artist,
    this.album,
    this.youtubeUrl,
    this.thumbnailUrl,
    this.confidence,
    this.offsetSeconds,
    this.spotifyUrl,
    this.appleMusicUrl,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      offsetSeconds: json['offset_seconds'] as int?,
      spotifyUrl: json['spotify_url'] as String?,
      appleMusicUrl: json['apple_music_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'youtube_url': youtubeUrl,
      'thumbnail_url': thumbnailUrl,
      'confidence': confidence,
      'offset_seconds': offsetSeconds,
      'spotify_url': spotifyUrl,
      'apple_music_url': appleMusicUrl,
    };
  }
}
