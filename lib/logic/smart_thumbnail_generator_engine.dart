import 'package:smart_thumbnail_generator_engine/models/frame_score.dart';
import 'package:smart_thumbnail_generator_engine/services/face_detection_service.dart';
import 'package:smart_thumbnail_generator_engine/services/frame_sampling_service.dart';
import 'package:smart_thumbnail_generator_engine/services/video_processing_optimizer_service.dart';
import 'package:smart_thumbnail_generator_engine/utils/utils.dart';

/// ---------------------------------------------------------------------------
/// VideoProcessingOrchestrator
///
/// High-level orchestrator for video thumbnail extraction.
/// Combines:
///   1. Frame extraction & scene detection
///   2. Optimized frame analysis (brightness, contrast, sharpness)
///   3. Motion analysis
///   4. Face detection reduction
///   5. Scoring & top-N selection
///
/// This is the recommended entry point for fetching top video thumbnails
/// using the optimized pipeline.
/// ---------------------------------------------------------------------------
class SmartThumbnailGeneratorEngine {

  /// -------------------------------------------------------------------------
  /// Fetch top thumbnails from a video (optimized pipeline)
  ///
  /// This method executes the **full pipeline**:
  /// 1. Extract frames from the video and detect scenes
  /// 2. Downscale frames for faster analysis
  /// 3️. Use isolates for parallel computation
  /// 4. Compute metrics: sharpness, brightness, contrast, motion
  /// 5. Apply face detection only on relevant frames
  /// 6. Compute total scores and return top-N frames
  ///
  /// Params:
  /// - [videoPath] : Path to the video file (local asset or file path)
  /// - [topN]      : Number of top frames to return
  ///
  /// Returns: List of [FrameScore] objects representing top frames
  /// -------------------------------------------------------------------------
  static Future<List<FrameInfos>> generateThumbnails({
    required String videoPath,
    int topN = 10,
  }) async {

    Utils.printf("Starting OPTIMIZED video pipeline for: $videoPath");

    // ===============================
    // Phase 1: Scene Detection & Frame Extraction
    // ===============================
    Utils.printf("Phase 1: Extracting frames and detecting scenes...");

    final scenes = await FrameSamplingSceneService.extractFramesFromVideo(
      videoPath: videoPath,
    );

    Utils.printf("Phase 1 completed: ${scenes.length} scenes detected");

    // Print scene summary
    for (final scene in scenes) {
      Utils.printf('Scene ${scene.sceneIndex} | frames: ${scene.frames.length}');
    }

    // ===============================
    // Phase 2+3+4: Optimized Frame Analysis & Scoring
    // ===============================
    Utils.printf("Phase 2: Starting optimized analysis + scoring pipeline...");

    final topThumbnails = await SmartVideoProcessingOptimizer.optimizedVideoPipeline(
      scenes: scenes,
      topN: topN,
    );

    // Print selected top frames
    Utils.printf("Top $topN thumbnails selected:");
    for (int i = 0; i < topThumbnails.length; i++) {
      final f = topThumbnails[i];
      Utils.printf(
        "${i + 1}. "
        "Score=${f.totalScore.toStringAsFixed(3)} | "
        "B=${f.brightness.toStringAsFixed(3)} | "
        "C=${f.contrast.toStringAsFixed(3)} | "
        "S=${f.sharpness.toStringAsFixed(3)} | "
        "M=${f.motion.toStringAsFixed(3)} | "
        "Face=${f.faceScore}",
      );
    }

    FaceDetectionService.close();

    return topThumbnails;
  }
}