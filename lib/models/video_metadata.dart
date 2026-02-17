library models.video_metadata;
/// Represents **global metadata** of a video source.
///
/// This is the root context object of the engine.
/// It provides all high-level information required
/// to configure decoding, sampling, processing, and scheduling.
///
/// Pipeline entry point:
/// VideoMetadata → Decoder → Frame → Scene → Scoring → Selection

class VideoMetadata {
  final String name;
  final String path;
  final int durationMs;
  final int? width;
  final int? height;
  final int? sizeBytes;
  final double? frameRate;

  const VideoMetadata({
    required this.name,
    required this.path,
    required this.durationMs,
    this.width,
    this.height,
    this.sizeBytes,
    this.frameRate,
  });

  @override
  String toString() 
    => '''
      VideoMetadata(
        name: $name
        durationMs: $durationMs
        resolution: ${width}x$height
        sizeBytes: $sizeBytes
        frameRate: $frameRate
      )
      ''';
}