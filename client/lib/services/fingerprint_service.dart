// No additional dependencies needed - uses only built-in Dart libraries

import 'dart:io';
import 'dart:typed_data';
import 'package:client/models/fingerprint_data.dart';

class FingerprintService {
  Future<Map<String, dynamic>> generateFingerprint(String audioFilePath) async {
    try {
      Map<String, dynamic> audioData;

      // Check file extension to determine how to process
      if (audioFilePath.toLowerCase().endsWith('.wav')) {
        audioData = await _readWavFile(audioFilePath);
      } else if (audioFilePath.toLowerCase().endsWith('.mp3')) {
        audioData = await _readMp3File(audioFilePath);
      } else {
        throw Exception(
          'Unsupported audio format. Only WAV and MP3 are supported.',
        );
      }

      // Generate simple time-domain fingerprints
      final fingerprints = _generateSimpleFingerprint(
        audioData['samples'],
        audioData['sampleRate'],
      );

      return {
        'error': 0,
        'data': fingerprints.map((fp) => fp.toJson()).toList(),
      };
    } catch (e) {
      return {'error': 1, 'message': e.toString(), 'data': []};
    }
  }

  Future<Map<String, dynamic>> _readWavFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    // Simple WAV parsing (your AudioService creates standard WAV files)
    final byteData = ByteData.sublistView(bytes);

    // Extract sample rate from WAV header (offset 24)
    final sampleRate = byteData.getUint32(24, Endian.little);

    // Find data chunk (usually starts at offset 44 for simple WAV)
    int dataStart = 44;

    // Extract 16-bit samples and convert to normalized floats
    final samples = <double>[];
    for (int i = dataStart; i < bytes.length - 1; i += 2) {
      final sample = byteData.getInt16(i, Endian.little);
      samples.add(sample / 32767.0); // Normalize to -1.0 to 1.0
    }

    return {'samples': samples, 'sampleRate': sampleRate};
  }

  Future<Map<String, dynamic>> _readMp3File(String filePath) async {
    // For MP3 files, we'll do a simplified approach
    // In a production app, you should use a proper MP3 decoder library
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    print('Processing MP3 file: $filePath (${bytes.length} bytes)');

    // Since we can't easily decode MP3 without external libraries,
    // we'll create a simplified fingerprint based on the raw bytes
    // This is not ideal but works as a basic implementation
    final samples = _extractSamplesFromMp3Bytes(bytes);

    return {
      'samples': samples,
      'sampleRate': 44100, // Assume standard sample rate
    };
  }

  List<double> _extractSamplesFromMp3Bytes(Uint8List bytes) {
    // Simplified approach: extract patterns from MP3 bytes
    // This is not a proper MP3 decoder but creates usable fingerprint data
    final samples = <double>[];

    // Skip MP3 header and look for frame data
    int startOffset = _findMp3DataStart(bytes);

    // Extract byte patterns and convert to pseudo-audio samples
    for (int i = startOffset; i < bytes.length - 1; i += 2) {
      // Combine two bytes to create a 16-bit-like value
      int value = (bytes[i] << 8) | bytes[i + 1];
      // Convert to signed and normalize
      if (value > 32767) value -= 65536;
      samples.add(value / 32767.0);
    }

    // If we don't have enough samples, pad with silence
    if (samples.length < 1000) {
      samples.addAll(List.filled(1000 - samples.length, 0.0));
    }

    print('Extracted ${samples.length} pseudo-samples from MP3');
    return samples;
  }

  int _findMp3DataStart(Uint8List bytes) {
    // Look for MP3 frame sync (0xFF followed by 0xE0-0xFF)
    for (int i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0xFF && (bytes[i + 1] & 0xE0) == 0xE0) {
        return i;
      }
    }
    // If no frame sync found, start from a reasonable offset
    return bytes.length > 100 ? 100 : 0;
  }

  List<FingerprintModel> _generateSimpleFingerprint(
    List<double> samples,
    int sampleRate,
  ) {
    final fingerprints = <FingerprintModel>[];

    // Simple approach: divide audio into chunks and create fingerprints
    const double chunkDurationSeconds = 0.1; // 100ms chunks
    final int samplesPerChunk = (sampleRate * chunkDurationSeconds).round();

    for (
      int i = 0;
      i < samples.length - samplesPerChunk;
      i += samplesPerChunk ~/ 2
    ) {
      final chunk = samples.sublist(i, i + samplesPerChunk);
      final anchorTime = i / sampleRate;

      // Create simple audio signature from chunk
      final signature = _createAudioSignature(chunk);
      final address = _hashSignature(signature, anchorTime);

      fingerprints.add(
        FingerprintModel(address: address, anchorTime: anchorTime),
      );
    }

    return fingerprints;
  }

  List<double> _createAudioSignature(List<double> chunk) {
    // Create a simple audio signature using statistical features
    final signature = <double>[];

    // 1. RMS Energy
    double rms = 0.0;
    for (final sample in chunk) {
      rms += sample * sample;
    }
    rms = rms / chunk.length;
    signature.add(rms);

    // 2. Zero Crossing Rate
    int zeroCrossings = 0;
    for (int i = 1; i < chunk.length; i++) {
      if ((chunk[i] >= 0) != (chunk[i - 1] >= 0)) {
        zeroCrossings++;
      }
    }
    signature.add(zeroCrossings / chunk.length);

    // 3. Spectral Centroid (simplified)
    double centroid = 0.0;
    double totalMagnitude = 0.0;
    for (int i = 0; i < chunk.length; i++) {
      final magnitude = chunk[i].abs();
      centroid += i * magnitude;
      totalMagnitude += magnitude;
    }
    if (totalMagnitude > 0) {
      centroid /= totalMagnitude;
    }
    signature.add(centroid / chunk.length);

    // 4. Peak amplitude
    double peak = 0.0;
    for (final sample in chunk) {
      if (sample.abs() > peak) {
        peak = sample.abs();
      }
    }
    signature.add(peak);

    // 5. Additional features for better MP3 handling
    // Mean absolute deviation
    double mean = chunk.reduce((a, b) => a + b) / chunk.length;
    double mad = 0.0;
    for (final sample in chunk) {
      mad += (sample - mean).abs();
    }
    mad /= chunk.length;
    signature.add(mad);

    // 6. Variance
    double variance = 0.0;
    for (final sample in chunk) {
      variance += (sample - mean) * (sample - mean);
    }
    variance /= chunk.length;
    signature.add(variance);

    return signature;
  }

  int _hashSignature(List<double> signature, double anchorTime) {
    // Create a consistent hash from the signature
    final buffer = StringBuffer();

    // Add time component
    buffer.write((anchorTime * 1000).round());

    // Add quantized signature values
    for (final value in signature) {
      buffer.write((value * 10000).round());
    }

    // Simple hash function
    int hash = 0;
    final str = buffer.toString();
    for (int i = 0; i < str.length; i++) {
      hash = ((hash * 31) + str.codeUnitAt(i)) & 0x7FFFFFFF;
    }

    return hash;
  }

  // Format for backend - Send address as key and convert anchorTime to uint32
  Map<String, dynamic> formatFingerprintForBackend(
    List<FingerprintModel> fingerprints,
  ) {
    final Map<String, dynamic> fingerprintMap = {};
    for (final fp in fingerprints) {
      // Use address as key (string) and convert anchorTime to milliseconds as uint32
      fingerprintMap[fp.address.toString()] = (fp.anchorTime * 1000).round();
    }
    print("Formatted fingerprint for backend: $fingerprintMap");
    return fingerprintMap;
  }
}
