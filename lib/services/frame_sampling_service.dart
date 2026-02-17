/// Frame sampling and scene detection service.
///
/// This service is responsible for:
/// 1. Extracting frames from a video at a smart sampling interval.
/// 2. Computing histograms for each frame.
/// 3. Detecting scene changes using histogram differences.
/// 4. Grouping frames into logical `Scene` objects.
///
/// Output:
/// ```text
/// Scene 0: [F0, F1, F2, ...]
/// Scene 1: [F3, F4, F5, ...]
/// ...
/// ```
///
/// Pipeline: Video → Frame Extraction → Histogram → Scene Detection → Scene List
library;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/frame.dart';
import '../models/scene.dart';
import '../services/video_metadata_extractor_service.dart';
import '../utils/utils.dart';

class FrameSamplingSceneService {
  /// Extracts frames from a video and groups them into scenes.
  ///
  /// [videoPath] → path to the video file
  /// [samplingTime] → optional, interval between frames in milliseconds
  ///                  if not provided, uses smart sampling based on video duration
  ///
  /// Returns a list of `Scene` objects, each containing its frames.
  static Future<List<Scene>> extractFramesFromVideo({
    required String videoPath,
    int? samplingTime,
  }) async {
    // --------------------------------------------
    // Phase 0 – Retrieve video metadata
    // --------------------------------------------
    final videoInfos = await VideoMetadataExtractorService.extractVideoMetadata(videoPath);
    final samplingTimeMs = samplingTime ?? Utils.smartSamplingMs(videoInfos.durationMs);
    
    Utils.printf("Video metadata: $videoInfos");
    Utils.printf("Sampling interval: ${samplingTimeMs}ms");

    final List<Frame> frames = [];
    final List<double> diffs = [];

    // --------------------------------------------
    // Phase 1 – Frame extraction + histogram computation
    // --------------------------------------------
    int frameIndex = 0;

    for (int t = 0; t < videoInfos.durationMs; t += samplingTimeMs) {
      final Uint8List? bytes = await VideoThumbnail.thumbnailData(
        video: videoInfos.path,
        timeMs: t,
        imageFormat: ImageFormat.JPEG,
        quality: 80,
      );

      if (bytes == null) continue;

      final image = img.decodeImage(bytes);
      if (image == null) continue;

      final histogram = HistogramUtils.computeHistogram(image);

      frames.add(Frame(
        index: frameIndex++,
        timestamp: Duration(milliseconds: t),
        image: image,
        histogram: histogram,
      ));
    }

    if (frames.isEmpty) return [];

    Utils.printf("Frames extracted: ${frames.length}");

    // --------------------------------------------
    // Phase 2 – Histogram difference computation
    // --------------------------------------------
    for (int i = 1; i < frames.length; i++) {
      final diff = HistogramUtils.distance(
        frames[i - 1].histogram,
        frames[i].histogram,
      );
      diffs.add(diff);
    }

    // Adaptive threshold based on mean difference
    final threshold = diffs.reduce((a, b) => a + b) / diffs.length;
    Utils.printf("Adaptive threshold (mean diff): $threshold");

    // --------------------------------------------
    // Phase 3 – Scene detection + grouping
    // --------------------------------------------
    final List<Scene> scenes = [];
    List<Frame> currentScene = [];

    int sceneIndex = 0;
    currentScene.add(frames.first);

    for (int i = 1; i < frames.length; i++) {
      final diff = diffs[i - 1];

      // New scene detected if difference exceeds threshold
      if (diff > threshold) {
        scenes.add(Scene(
          sceneIndex: sceneIndex++,
          frames: List.from(currentScene),
        ));
        currentScene.clear();
      }
      currentScene.add(frames[i]);
    }

    // Push the last scene
    if (currentScene.isNotEmpty) {
      scenes.add(Scene(
        sceneIndex: sceneIndex,
        frames: currentScene,
      ));
    }

    Utils.printf("Scene detection complete → ${scenes.length} scenes");

    return scenes;
  }
}