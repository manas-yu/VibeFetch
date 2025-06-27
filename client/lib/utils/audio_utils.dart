import 'dart:typed_data';

class AudioUtils {
  // Convert audio samples to fingerprint format
  static List<double> normalizeAudioSamples(Uint8List audioBytes) {
    // Convert bytes to double array normalized between -1.0 and 1.0
    List<double> samples = [];

    for (int i = 0; i < audioBytes.length - 1; i += 2) {
      // Convert 16-bit little-endian to double
      int sample = (audioBytes[i + 1] << 8) | audioBytes[i];
      if (sample >= 32768) sample -= 65536; // Convert to signed
      samples.add(sample / 32768.0); // Normalize to -1.0 to 1.0
    }

    return samples;
  }

  // Format duration for display
  static String formatDuration(double durationInSeconds) {
    final minutes = (durationInSeconds / 60).floor();
    final seconds = (durationInSeconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
