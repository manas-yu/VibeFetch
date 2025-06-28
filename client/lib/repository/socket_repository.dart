// socket_repository.dart
import 'dart:convert';

import 'package:client/repository/clients/socket_client.dart';
import 'package:client/models/download_status.dart';
import 'package:client/models/recording_data.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketRepository {
  final _socketClient = SocketClient.instance.socket!;

  Socket get socketClient => _socketClient;

  // Initialize socket listeners
  void initializeListeners({
    required Function(String) onMatches,
    required Function(DownloadStatusModel) onDownloadStatus,
    required Function(int) onTotalSongs,
  }) {
    print('Initializing socket listeners...');
    // Listen for matches from fingerprint recognition
    _socketClient.on('matches', (data) {
      // data will be just a string
      final matchString = data as String;
      print('Received match string: $data');
      print('Received match string: ' + matchString + data);
      onMatches(matchString);
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

  void listenYtIds({required Function(List<String>) onYtIds}) {
    _socketClient.on('allYouTubeIDs', (data) {
      try {
        List<String> ytIds;
        if (data is String) {
          final decoded = jsonDecode(data);
          ytIds = List<String>.from(decoded.map((e) => e.toString()));
        } else if (data is List) {
          ytIds = List<String>.from(data.map((e) => e.toString()));
        } else {
          ytIds = [];
        }
        onYtIds(ytIds);
      } catch (e) {
        print('Error parsing YouTube IDs: $e');
        onYtIds([]); // Return empty list on error
      }
    });
  }

  // Get all YouTube IDs
  void getAllYTIds() {
    print("Sending request for YouTube IDs");
    _socketClient.emit('getAllYouTubeIDs');
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
