// socket_repository.dart
import 'dart:convert';

import 'package:client/repository/clients/socket_client.dart';
import 'package:client/models/download_status.dart';
import 'package:client/models/match_model.dart';
import 'package:client/models/recording_data.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketRepository {
  final _socketClient = SocketClient.instance.socket!;

  Socket get socketClient => _socketClient;

  // Initialize socket listeners
  void initializeListeners({
    required Function(List<MatchModel>) onMatches,
    required Function(DownloadStatusModel) onDownloadStatus,
    required Function(int) onTotalSongs,
  }) {
    print('Initializing socket listeners...');
    // Listen for matches from fingerprint recognition
    _socketClient.on('matches', (data) {
      final matchesJson = data as String;
      // Use a logging framework in production, e.g., logger
      // logger.i(matchesJson);
      final List<dynamic> decoded = jsonDecode(matchesJson);
      print(decoded);
      final matches = decoded
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
      // logger.i('Received matches: $matches');
      onMatches(matches);
    });

    // Listen for download status messages
    _socketClient.on('downloadStatus', (data) {
      final statusJson = data as String;
      final statusData = jsonDecode(statusJson);
      final downloadStatus = DownloadStatusModel.fromJson(statusData);
      print('Download status: ${downloadStatus}');
      onDownloadStatus(downloadStatus);
    });

    // Listen for total songs count
    _socketClient.on('totalSongs', (data) {
      final totalSongs = data as int;
      onTotalSongs(totalSongs);
      print('Total songs count: $totalSongs');
    });
  }

  // Request total songs count
  void requestTotalSongs() {
    _socketClient.emit('totalSongs', '');
  }

  // Send audio fingerprint for recognition
  void sendFingerprint(Map<String, dynamic> fingerprintData) {
    final fingerprintJson = jsonEncode({'fingerprint': fingerprintData});
    print("fingerprint data in socket client: $fingerprintJson");
    _socketClient.emit('newFingerprint', fingerprintJson);
  }

  // Send recorded audio data
  void sendRecording(RecordDataModel recordData) {
    final recordJson = jsonEncode(recordData.toJson());
    print("recording data in socket clinet:" + recordJson);
    _socketClient.emit('newRecording', recordJson);
  }

  // Add song from URL (for admin functionality)
  void addSongFromUrl({required String url}) {
    _socketClient.emit('newDownload', url);
  }

  // Dispose listeners
  void dispose() {
    _socketClient.off('matches');
    _socketClient.off('downloadStatus');
    _socketClient.off('totalSongs');
    _socketClient.disconnect();
  }
}
