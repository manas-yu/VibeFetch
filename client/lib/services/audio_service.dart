import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _recordingTimer;
  String? _recordingPath;

  // Callback for when auto-stop occurs
  Function()? _onAutoStop;

  // Start recording with specified duration (default 10 seconds)
  Future<void> startRecording({
    int durationSeconds = 10,
    Function()? onAutoStop,
  }) async {
    try {
      if (await _recorder.hasPermission()) {
        print('Microphone permission granted, starting recording...');
        final tempDir = await getDownloadsDirectory();
        _recordingPath =
            '${tempDir?.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        _onAutoStop = onAutoStop;

        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          bitRate: 128000,
          numChannels: 1, // Mono recording
        );

        await _recorder.start(config, path: _recordingPath!);
        print('Recording started at: $_recordingPath');

        // Auto-stop after specified duration
        _recordingTimer = Timer(Duration(seconds: durationSeconds), () {
          print('Auto-stopping recording after $durationSeconds seconds');
          _onAutoStop?.call(); // Notify the notifier to handle the stop
        });
      } else {
        throw Exception('Microphone permission not granted');
      }
    } catch (e) {
      _cleanup();
      throw Exception('Failed to start recording: $e');
    }
  }

  // Stop recording and return the recorded file path
  Future<String?> stopRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      if (!await _recorder.isRecording()) {
        print('Recorder is not currently recording');
        return _recordingPath; // Return the last recorded path if available
      }

      final path = await _recorder.stop();
      print('Recording stopped, file path: $path');

      if (path == null || path.isEmpty) {
        throw Exception('Recording path is null or empty');
      }

      // Verify file exists and has content
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Recording file does not exist at: $path');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Recording file is empty');
      }

      print(
        'Recording stopped successfully, file saved at: $path (${fileSize} bytes)',
      );
      _recordingPath = path;
      return path;
    } catch (e) {
      _cleanup();
      throw Exception('Failed to stop recording: $e');
    }
  }

  // Force stop recording without processing (for cleanup)
  Future<void> cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      // Delete the recording file if it exists
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
          print('Cancelled recording file deleted: $_recordingPath');
        }
      }

      _cleanup();
    } catch (e) {
      print('Error during recording cancellation: $e');
      _cleanup();
    }
  }

  // Convert audio file to base64 string (for sending to backend)
  Future<String> audioFileToBase64(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist at: $filePath');
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Audio file is empty');
      }

      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Failed to convert audio to base64: $e');
    }
  }

  // Get audio file metadata
  Future<Map<String, dynamic>> getAudioMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist at: $filePath');
      }

      final bytes = await file.readAsBytes();
      if (bytes.length < 44) {
        throw Exception('Invalid WAV file: too small');
      }

      final byteData = ByteData.sublistView(bytes);

      // WAV header parsing
      // Check if it's a valid WAV file
      final riffHeader = String.fromCharCodes(bytes.sublist(0, 4));
      final waveHeader = String.fromCharCodes(bytes.sublist(8, 12));

      if (riffHeader != 'RIFF' || waveHeader != 'WAVE') {
        throw Exception('Invalid WAV file format');
      }

      final channels = byteData.getUint16(22, Endian.little);
      final sampleRate = byteData.getUint32(24, Endian.little);
      final bitsPerSample = byteData.getUint16(34, Endian.little);
      final dataSize = byteData.getUint32(40, Endian.little);

      // Calculate duration
      final duration = dataSize / (sampleRate * channels * (bitsPerSample / 8));

      return {
        'channels': channels,
        'sampleRate': sampleRate,
        'sampleSize': bitsPerSample,
        'duration': duration,
        'fileSize': bytes.length,
      };
    } catch (e) {
      throw Exception('Failed to get audio metadata: $e');
    }
  }

  // Check if currently recording
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (e) {
      print('Error checking recording status: $e');
      return false;
    }
  }

  // Get the current recording path
  String? get currentRecordingPath => _recordingPath;

  // Clean up internal state
  void _cleanup() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _onAutoStop = null;
    _recordingPath = null;
  }

  // Dispose resources
  void dispose() {
    _cleanup();
    _recorder.dispose();
  }
}
