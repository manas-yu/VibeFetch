class SongAddRequestModel {
  final String url;
  final String title;
  final String artist;

  SongAddRequestModel({
    required this.url,
    required this.title,
    required this.artist,
  });

  factory SongAddRequestModel.fromJson(Map<String, dynamic> json) {
    return SongAddRequestModel(
      url: json['url'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'title': title, 'artist': artist};
  }
}
