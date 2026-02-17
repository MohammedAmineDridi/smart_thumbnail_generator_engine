import 'package:smart_thumbnail_generator_engine/models/frame.dart';

/// Represents the **scoring result** of a single video frame.
///
/// This model is part of the thumbnail selection pipeline.
/// Each `FrameScore` aggregates multiple analysis metrics
/// and produces a final `totalScore` used for ranking frames.

class FrameInfos {
  final Frame frame;
  final double sharpness;
  final double brightness;
  final double contrast;
  final double motion;
  final double faceScore;
  final double totalScore;

  FrameInfos({
    required this.frame,
    required this.sharpness,
    required this.brightness,
    required this.contrast,
    required this.motion,
    required this.faceScore,
    required this.totalScore,
  });

  
  @override
  String toString() 
    => '''
      FrameInfos(
        frame: $frame,
        sharpness: $sharpness
        brightness: $brightness,
        contrast: $contrast
        motion: $motion
        faceScore: $faceScore
        totalScore: $totalScore
      )
      ''';
}