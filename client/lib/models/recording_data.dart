class RecordDataModel {
  final String audio; // Base64 encoded audio data
  final int channels;
  final int sampleRate;
  final int sampleSize;
  final double duration;

  RecordDataModel({
    required this.audio,
    required this.channels,
    required this.sampleRate,
    required this.sampleSize,
    required this.duration,
  });

  factory RecordDataModel.fromJson(Map<String, dynamic> json) {
    return RecordDataModel(
      audio: json['audio'] as String,
      channels: json['channels'] as int,
      sampleRate: json['sampleRate'] as int,
      sampleSize: json['sampleSize'] as int,
      duration: (json['duration'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio': audio,
      'channels': channels,
      'sampleRate': sampleRate,
      'sampleSize': sampleSize,
      'duration': duration,
    };
  }
}
