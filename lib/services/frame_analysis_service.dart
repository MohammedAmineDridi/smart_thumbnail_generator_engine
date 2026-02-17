/// Frame Analysis Service – Phase 2 of the engine.
///
/// Computes **visual metrics** for frames including:
/// - Sharpness (image clarity)
/// - Brightness (overall light level)
/// - Contrast (pixel intensity spread)
/// - Motion (temporal change between frames)
/// - Face presence (0.0 → 1.0)
///
/// This service is a **pure computation layer**:
/// - Stateless
/// - Isolate-friendly
/// - Pipeline-ready
///
/// Usage:
/// ```dart
/// final sharpness = FrameAnalysisService.computeSharpness(frame.image);
/// final motion = FrameAnalysisService.computeMotion(curr, prev);
/// final sceneIdeal = await FrameAnalysisService.computeSceneIdealValues(sceneFrames);
/// ```
library;

import 'dart:math';
import 'package:image/image.dart' as img;
import '../models/scene_ideal_metrics.dart';
import 'face_detection_service.dart';

class FrameAnalysisService {
  // -------------------------------------------------
  // 1. Sharpness – How “clear” an image is
  // -------------------------------------------------
  ///
  /// Sharpness ≈ average intensity change between neighboring pixels
  /// - Sharp image → many edges → high-frequency changes → sharpness ↑
  /// - Blurry image → smooth transitions → sharpness ↓
  static double computeSharpness(img.Image image) {
    double sum = 0;
    int count = 0;

    for (int y = 1; y < image.height; y++) {
      for (int x = 1; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final px = image.getPixel(x - 1, y);
        final py = image.getPixel(x, y - 1);

        final dx = ((p.r - px.r).abs() +
                (p.g - px.g).abs() +
                (p.b - px.b).abs()) / 3;
        final dy = ((p.r - py.r).abs() +
                (p.g - py.g).abs() +
                (p.b - py.b).abs()) / 3;

        sum += dx + dy;
        count += 2; // two measurements per pixel (horizontal + vertical)
      }
    }

    return (sum / count) / image.maxChannelValue;
  }

  // -------------------------------------------------
  // 2. Brightness – How bright the image is
  // -------------------------------------------------
  ///
  /// Brightness ≈ average pixel intensity
  /// - 0.0 → completely dark
  /// - 1.0 → completely bright
  static double computeBrightness(img.Image image) {
    double sum = 0;
    for (final p in image) {
      sum += (p.r + p.g + p.b) / 3;
    }
    return sum / (image.width * image.height * image.maxChannelValue);
  }

  // -------------------------------------------------
  // 3. Contrast – Spread of pixel intensities
  // -------------------------------------------------
  ///
  /// Contrast ≈ variance of pixel brightness
  /// - Low variance → flat/boring frame
  /// - High variance → visually striking
  static double computeContrast(img.Image image) {
    final mean = computeBrightness(image);
    double variance = 0;
    for (final p in image) {
      final brightness = ((p.r + p.g + p.b) / 3) / image.maxChannelValue;
      variance += (brightness - mean) * (brightness - mean);
    }
    return sqrt(variance / (image.width * image.height));
  }

  // -------------------------------------------------
  // 4. Motion – Temporal changes between frames
  // -------------------------------------------------
  ///
  /// Motion ≈ average pixel difference between two frames
  /// - Identical frames → motion ≈ 0
  /// - Fast action → motion ↑
  static double computeMotion(img.Image current, img.Image previous) {
    if (current.width != previous.width || current.height != previous.height) {
      return 0.0;
    }

    double diff = 0.0;
    final totalPixels = current.width * current.height;

    for (int y = 0; y < current.height; y++) {
      for (int x = 0; x < current.width; x++) {
        final p1 = current.getPixel(x, y);
        final p2 = previous.getPixel(x, y);

        diff += ((p1.r - p2.r).abs() +
                (p1.g - p2.g).abs() +
                (p1.b - p2.b).abs()) / 3;
      }
    }

    return diff / (totalPixels * current.maxChannelValue);
  }

  // -------------------------------------------------
  // 5. Face Detection Score (0.0 → 1.0)
  // -------------------------------------------------
  ///
  /// Uses MLKit to detect faces
  static Future<double> computeFaceDetection(img.Image image) async {
    return await FaceDetectionService.detectFaceScoreFromImage(image);
  } 

  // -------------------------------------------------
  // 6. Scene Ideal Metrics – average values per scene
  // -------------------------------------------------
  ///
  /// Computes dynamic **ideal metrics** for a scene
  /// Input: list of frames (images)
  /// Output: `SceneIdealMetrics` (brightness, contrast, sharpness)
  static Future<SceneIdealMetrics> computeSceneIdealValues(
    List<img.Image> frames) async {
    double sumBrightness = 0;
    double sumContrast = 0;
    double sumSharpness = 0;

    for (final frame in frames) {
      sumBrightness += computeBrightness(frame);
      sumContrast += computeContrast(frame);
      sumSharpness += computeSharpness(frame);
    }

    final n = frames.length;
    return SceneIdealMetrics(
      brightnessIdeal: sumBrightness / n,
      contrastIdeal: sumContrast / n,
      sharpnessIdeal: sumSharpness / n,
    );
  }
}