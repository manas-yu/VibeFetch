class DownloadStatusModel {
  final String message;
  final String? type; // 'info', 'success', 'error', or null

  DownloadStatusModel({required this.message, this.type});

  factory DownloadStatusModel.fromJson(Map<String, dynamic> json) {
    return DownloadStatusModel(
      message: json['message'] as String,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'type': type};
  }

  bool get isInfo => type == 'info';
  bool get isSuccess => type == 'success';
  bool get isError => type == 'error';
}
