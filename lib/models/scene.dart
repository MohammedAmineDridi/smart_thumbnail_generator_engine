import 'frame.dart';

/// Represents a **logical scene segment** in a video.
///
/// A `Scene` is a group of consecutive frames that belong to
/// the same visual context (shot/scene).
///
/// Pipeline example:
/// Video → Frame Extraction → Scene Detection → Scene → Scoring → Selection
///
/// Used for:
/// - Scene cut detection
/// - Shot grouping
/// - Best-frame selection per scene
/// - Video summarization
/// - Highlight extraction

class Scene {
  final int sceneIndex;
  final List<Frame> frames;

  Scene({
    required this.sceneIndex,
    required this.frames,
  });

  @override
  String toString() => "Scene(sceneIndex: $sceneIndex,frames: ${frames.map((f)=>f.toString())})";
}