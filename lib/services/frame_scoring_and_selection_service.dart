/// Frame Scoring and Selection Service – Phase 3 of the engine.
///
/// Responsibilities:
/// 1. Compute a normalized score for each frame based on visual metrics:
///    - Sharpness
///    - Brightness
///    - Contrast
///    - Motion
///    - Face presence
/// 2. Rank frames by total score
/// 3. Select top-N frames as thumbnails
///
/// This service is **stateless**, pipeline-ready, and can be used with async frame processing.
library services.frame_scoring_and_selection;

import '../models/frame.dart';
import '../models/frame_score.dart';
import 'frame_analysis_service.dart';
import '../utils/consts.dart';

class FrameScoringService {
  // -------------------------------------------------
  // 0. Helper: score a metric based on distance from ideal
  // -------------------------------------------------
  ///
  /// Converts a metric into a normalized score [0.0 → 1.0] based on ideal value.
  /// - value = current metric
  /// - ideal = ideal/target metric
  /// - maxDistance = maximum deviation considered
  ///
  /// Output:
  /// - 1.0 → exactly ideal
  /// - 0.0 → exceeds maxDistance
  static double scoreOptimal(double value, double ideal, double maxDistance) {
    final distance = (value - ideal).abs();
    return (1 - (distance / maxDistance)).clamp(0.0, 1.0);
  }

  // -------------------------------------------------
  // 1. Compute frame score for ONE frame
  // -------------------------------------------------
  ///
  /// Weighted aggregation of visual metrics.
  ///
  /// Metrics:
  /// - sharpness, brightness, contrast → quality metrics
  /// - motion → temporal stability (less motion = better)
  /// - faceScore → face presence (0.0 → 1.0)
  ///
  /// Weights can be adjusted per use-case.
  static double computeFrameScore({
    required double sharpness,
    required double brightness,
    required double contrast,
    required double motion,
    required double faceScore,
    double? idealBrightness,
    double? idealContrast,
    double? idealSharpness,

    // Weights (tweak per use-case)
    double wSharp = sharpnessWeightConst,
    double wBright = brigthnessWeightConst,
    double wContrast = contrastWeightConst,
    double wMotion = motionWeightConst,
    double wFace = faceWeightConst,
  }) {
    // Score metrics based on ideal values
    final brightnessScore = scoreOptimal(brightness, idealBrightness ?? brightnessIdealConst, maxBrightnessDistanceConst);

    final contrastScore = scoreOptimal(contrast, idealContrast ?? contrastIdealConst, maxContrastDistanceConst);

    final sharpnessScore = scoreOptimal(sharpness, idealSharpness ?? sharpnessIdealConst, maxSharpnessDistanceConst);

    final motionScore = 1.0 - motion; // less motion = higher score

    // Face score is already normalized (0.0 → 1.0)

    return (sharpnessScore * wSharp) +
        (brightnessScore * wBright) +
        (contrastScore * wContrast) +
        (motionScore * wMotion) +
        (faceScore * wFace);
  }

  // -------------------------------------------------
  // 2. Score all frames in a scene/video
  // -------------------------------------------------
  ///
  /// Computes per-frame metrics using `FrameAnalysisService`, then calculates total score.
  /// Returns a list of `FrameScore` objects.
  static Future<List<FrameInfos>> scoreFrames({
    required List<Frame> frames,
  }) async {
    final List<FrameInfos> scoredFrames = [];

    // Compute ideal values once per scene for brightness/contrast/sharpness
    final ideals = await FrameAnalysisService.computeSceneIdealValues(
      frames.map((f) => f.image).toList(),
    );

    for (int i = 0; i < frames.length; i++) {
      final frame = frames[i];

      // ---------- Compute metrics ----------
      final sharpness = FrameAnalysisService.computeSharpness(frame.image);
      final brightness = FrameAnalysisService.computeBrightness(frame.image);
      final contrast = FrameAnalysisService.computeContrast(frame.image);
      final motion =  (i > 0) ? FrameAnalysisService.computeMotion(frame.image, frames[i - 1].image) : 0.0;

      final faceScore = await FrameAnalysisService.computeFaceDetection(frame.image);

      // ---------- Compute total score ----------
      final totalScore = computeFrameScore(
        sharpness: sharpness,
        brightness: brightness,
        contrast: contrast,
        motion: motion,
        faceScore: faceScore,
        idealBrightness: ideals.brightnessIdeal,
        idealContrast: ideals.contrastIdeal,
        idealSharpness: ideals.sharpnessIdeal,
      );

      scoredFrames.add(FrameInfos(
        frame: frame,
        sharpness: sharpness,
        brightness: brightness,
        contrast: contrast,
        motion: motion,
        faceScore: faceScore,
        totalScore: totalScore,
      ));
    }

    return scoredFrames;
  }

  // -------------------------------------------------
  // 3. Select top-N frames as thumbnails
  // -------------------------------------------------
  ///
  /// Sorts frames by total score descending and returns top [n] frames.
  static List<FrameInfos> getTopNThumbnail(List<FrameInfos> scoredFrames,int n) {
    scoredFrames.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return scoredFrames.take(n).toList();
  }
}