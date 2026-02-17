import 'package:image/image.dart' as img;

/// Represents a **single extracted frame** from a video stream.
///
/// This is the atomic data unit of the thumbnail generation engine.
/// Every processing stage operates on this object:
///
/// Video → Decoder → Frame → Analysis → Scoring → Ranking → Selection

class Frame {
  final int index;
  final Duration timestamp;
  final img.Image image;
  final List<double> histogram;

  Frame({
    required this.index,
    required this.timestamp,
    required this.image,
    required this.histogram,
  });

  @override
  String toString() => "Frame(index: $index, image: $image, histogram: $histogram, timeMs: $timestamp)";
}