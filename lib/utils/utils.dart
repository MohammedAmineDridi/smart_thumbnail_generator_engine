import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:smart_thumbnail_generator_engine/utils/consts.dart';

class Utils {
  /// -------------------------------
  /// Downscale image for faster analysis
  /// -------------------------------
  /// Reduces resolution for metrics computation (brightness, sharpness, contrast)
  /// without altering the original frame. 
  /// Example: 1920x1080 → 320x180 → ~35x faster
  static img.Image downscaleImage(img.Image image) {
    return img.copyResize(image, width: 320);
  }

  /// -------------------------------
  /// Smart sampling strategy based on video duration
  /// -------------------------------
  /// Returns sampling interval in milliseconds for frame extraction
  static int smartSamplingMs(int durationMs) {
    if (durationMs < shortVideoDuration) return shortDurationVideoSamplingTime;
    if (durationMs < midVideoDuration) return midDurationVideoSamplingTime;
    return longVideoDuration;
  }

  static void printf(String message) {
    debugPrint(message);
  }
}

/// ==============================================
/// Histogram Utilities
/// ==============================================
class HistogramUtils {
  /// -------------------------------
  /// Compute RGB histogram (normalized)
  /// -------------------------------
  ///  - 8 bins per channel (R, G, B)
  ///  - Returns a list of 24 values (percentages)
  ///  - Normalized to [0, 1] to allow comparison between images of different sizes
  static List<double> computeHistogram(img.Image image, {int bins = 8}) {
    final histR = List.filled(bins, 0);
    final histG = List.filled(bins, 0);
    final histB = List.filled(bins, 0);

    for (final p in image) {
      histR[(p.r * bins ~/ 256).clamp(0, bins - 1)]++;
      histG[(p.g * bins ~/ 256).clamp(0, bins - 1)]++;
      histB[(p.b * bins ~/ 256).clamp(0, bins - 1)]++;
    }

    final total = image.width * image.height;

    // Convert counts to percentages (0.0 → 1.0)
    return [
      ...histR.map((v) => v / total),
      ...histG.map((v) => v / total),
      ...histB.map((v) => v / total),
    ];
  }

  /// -------------------------------
  /// Compute histogram distance between two frames
  /// -------------------------------
  /// Uses L1 distance (sum of absolute differences)
  /// - 0 → identical histograms
  /// - Larger values → more different
  static double distance(List<double> h1, List<double> h2) {
    double sum = 0;
    for (int i = 0; i < h1.length; i++) {
      sum += (h1[i] - h2[i]).abs();
    }
    return sum;
  }
}