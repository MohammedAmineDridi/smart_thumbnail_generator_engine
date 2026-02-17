library models.scene_ideal_metrics;
/// Defines the **ideal visual profile** of a scene.
///
/// This model represents the *target feature vector* used
/// for evaluating and scoring frames.

class SceneIdealMetrics {
  final double brightnessIdeal;
  final double contrastIdeal;
  final double sharpnessIdeal;

  SceneIdealMetrics({
    required this.brightnessIdeal,
    required this.contrastIdeal,
    required this.sharpnessIdeal,
  });

  @override
  String toString() => 'SceneIdealMetrics(brightness=$brightnessIdeal, contrast=$contrastIdeal, sharpness=$sharpnessIdeal)';
}