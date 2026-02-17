library services.video_metadata_extractor_service;
/// Video Metadata Extractor Service
///
/// Loads a video from an asset path or file, writes it to a temporary location,
/// and extracts detailed metadata including:
/// - Duration
/// - Resolution (width x height)
/// - File size
/// - Frame rate
///
/// Returns a strongly-typed `VideoMetadata` object suitable for pipeline usage.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_metadata.dart';

class VideoMetadataExtractorService {

  static final FlutterVideoInfo _videoInfo = FlutterVideoInfo();

  // -------------------------------------------------
  // Extract video metadata from asset path
  // -------------------------------------------------
  ///
  /// Loads a video from assets or file path, writes to temporary directory,
  /// and returns structured `VideoMetadata`.

  static Future<VideoMetadata> extractVideoMetadata(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);

    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final tempFile = File('${tempDir.path}/$fileName');

    await tempFile.writeAsBytes(
      byteData.buffer.asUint8List(),
      flush: true,
    );

    final info = await _videoInfo.getVideoInfo(tempFile.path);

    if (info == null) {
      throw Exception('Unable to extract video metadata for $assetPath');
    }

    return VideoMetadata(
      name: fileName,
      path: tempFile.path,
      durationMs: (info.duration ?? 0).toInt(),
      width: info.width,
      height: info.height,
      sizeBytes: info.filesize,
      frameRate: info.framerate,
    );
  }
}