library services.video_processing_optimizer_service;
/// Smart Video Processing Optimizer
///
/// This service orchestrates the full **frame analysis pipeline**:
/// 1. Downscale frames early for faster processing
/// 2. Smart sampling based on video duration
/// 3. Frame filtering based on metrics (brightness, contrast, sharpness, motion)
/// 4. Face detection
/// 5. Motion calculation
/// 6. Total scoring and top-N thumbnail selection
/// 
/// Uses an **Isolate Pool** to limit concurrency to the number of CPU cores.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'package:smart_thumbnail_generator_engine/models/frame.dart';
import 'package:smart_thumbnail_generator_engine/models/frame_score.dart';
import 'package:smart_thumbnail_generator_engine/models/scene.dart';
import 'package:smart_thumbnail_generator_engine/services/frame_analysis_service.dart';
import 'package:smart_thumbnail_generator_engine/services/frame_scoring_and_selection_service.dart';
import 'package:smart_thumbnail_generator_engine/utils/utils.dart';

class SmartVideoProcessingOptimizer {

  // -------------------------------------------------
  // Worker Isolate
  // -------------------------------------------------
  /// _worker processes a single frame in a separate isolate:
  /// 1. Downscale the frame early to reduce computation
  /// 2. Compute brightness, sharpness, and contrast
  /// 3. Send results back to the main isolate
  static void _worker(List<dynamic> args) {
    final sendPort = args[0] as SendPort;
    final Frame frame = args[1];

    // Downscale early for faster computation
    final smallImage = Utils.downscaleImage(frame.image);

    // Compute metrics
    final sharpness = FrameAnalysisService.computeSharpness(smallImage);
    final brightness = FrameAnalysisService.computeBrightness(smallImage);
    final contrast = FrameAnalysisService.computeContrast(smallImage);

    // Send back results
    sendPort.send({
      'frame': frame,
      'sharpness': sharpness,
      'brightness': brightness,
      'contrast': contrast,
    });
  }

  // -------------------------------------------------
  // Spawn a single worker isolate
  // -------------------------------------------------
  /// Sends a frame to a background isolate for processing and waits for the result
  static Future<Map<String, dynamic>> _spawnWorker(Frame frame) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_worker, [receivePort.sendPort, frame]);
    final result = await receivePort.first as Map<String, dynamic>;
    receivePort.close();
    return result;
  }

  // -------------------------------------------------
  // Process one scene using a pool of isolates
  // -------------------------------------------------
  /// Executes **frame analysis** in parallel using a queue and isolate pool
  /// Steps:
  /// 1. Spawn isolates up to the number of CPU cores
  /// 2. Compute brightness, sharpness, and contrast
  /// 3. Batch face detection
  /// 4. Compute motion and total frame score
  static Future<List<FrameInfos>> processScene(Scene scene) async {
    final frames = scene.frames;
    final nCores = Platform.numberOfProcessors; // Pool size = CPU cores
    Utils.printf("CPU cores available = $nCores");

    final tempScores = <FrameInfos>[];
    final queue = Queue<Frame>.from(frames); // Frames waiting to be processed
    final activeWorkers = <Future<Map<String, dynamic>>>[]; // Pool of active isolates

    // STEP 1: Spawn workers while queue is not empty
    while (queue.isNotEmpty || activeWorkers.isNotEmpty) {
      while (queue.isNotEmpty && activeWorkers.length < nCores) {
        final frame = queue.removeFirst();
        final future = _spawnWorker(frame);
        activeWorkers.add(future);
      }

      // Wait for any worker to finish
      Future<Map<String, dynamic>> completedFuture = await Future.any(activeWorkers.map((f) => f.then((_) => f))); 
      final completed = await completedFuture; 
      activeWorkers.remove(completedFuture);

      tempScores.add(
        FrameInfos(
          frame: completed['frame'],
          sharpness: completed['sharpness'],
          brightness: completed['brightness'],
          contrast: completed['contrast'],
          motion: 0.0,
          faceScore: 0.0,
          totalScore: 0.0,
        ),
      );
    }

    // STEP 2: Face detection (parallel batch faces detection)
    final faceFutures = tempScores.map((f) async {
      final score = await FrameAnalysisService.computeFaceDetection(f.frame.image);
      return FrameInfos(
        frame: f.frame,
        sharpness: f.sharpness,
        brightness: f.brightness,
        contrast: f.contrast,
        motion: f.motion,
        faceScore: score,
        totalScore: f.totalScore,
      );
    }).toList();

    final withFaces = await Future.wait(faceFutures);

    // STEP 3: Compute motion + total score using scene ideal metrics
    final scored = <FrameInfos>[];
    final ideals = await FrameAnalysisService.computeSceneIdealValues(
      withFaces.map((f) => f.frame.image).toList(),
    );

    for (int i = 0; i < withFaces.length; i++) {
      final f = withFaces[i];
      final motion = (i > 0) ? FrameAnalysisService.computeMotion(f.frame.image, withFaces[i - 1].frame.image) : 0.0;

      final total = FrameScoringService.computeFrameScore(
        sharpness: f.sharpness,
        brightness: f.brightness,
        contrast: f.contrast,
        motion: motion,
        faceScore: f.faceScore,
        idealBrightness: ideals.brightnessIdeal,
        idealContrast: ideals.contrastIdeal,
        idealSharpness: ideals.sharpnessIdeal,
      );

      scored.add(
        FrameInfos(
          frame: f.frame,
          sharpness: f.sharpness,
          brightness: f.brightness,
          contrast: f.contrast,
          motion: motion,
          faceScore: f.faceScore,
          totalScore: total,
        ),
      );
    }

    return scored;
  }

  // -------------------------------------------------
  // Full video pipeline
  // -------------------------------------------------
  /// Optimized video thumbnail extraction pipeline
  /// Steps:
  /// 1. Process each scene with isolates
  /// 2. Compute all metrics and scores
  /// 3. Select top-N frames globally
  static Future<List<FrameInfos>> optimizedVideoPipeline({
    required List<Scene> scenes,
    int topN = 5,
  }) async {
    final allResults = <FrameInfos>[];

    for (final scene in scenes) {
      final scoredFrames = await processScene(scene);
      allResults.addAll(scoredFrames);
    }

    allResults.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return allResults.take(topN).toList();
  }
}