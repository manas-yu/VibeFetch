class FingerprintModel {
  final int address;
  final double anchorTime;

  FingerprintModel({required this.address, required this.anchorTime});

  factory FingerprintModel.fromJson(Map<String, dynamic> json) {
    return FingerprintModel(
      address: json['address'] as int,
      anchorTime: (json['anchorTime'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'address': address, 'anchorTime': anchorTime};
  }
}
