// No additional dependencies needed - uses only built-in Dart libraries

import 'dart:io';
import 'dart:typed_data';
import 'package:client/models/fingerprint_data.dart';

class FingerprintService {
  Future<Map<String, dynamic>> generateFingerprint(String audioFilePath) async {
    try {
      // Since your AudioService already records as mono WAV, we can read it directly
      final audioData = await _readWavFile(audioFilePath);

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

  // Format for backend - FIXED: Send address as key and convert anchorTime to uint32
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
