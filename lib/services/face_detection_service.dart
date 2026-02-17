import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Face Detection service : takes image frame input and return : 0 (no face detected) / 1 (face detected)

class FaceDetectionService {
  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  /// Detect faces in an image file
  /// Returns 1.0 if at least one face detected, 0.0 otherwise
  static Future<double> detectFaceScoreFromImage(img.Image image) async {
    // Encode image to JPEG => Write to temp file => Create InputImage from file path => Run face detection 
    final jpegBytes = img.encodeJpg(image);
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/face_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(jpegBytes);
    
    final inputImage = InputImage.fromFilePath(file.path);
    
    final faces = await _faceDetector.processImage(inputImage);
    return faces.isNotEmpty ? 1.0 : 0.0;
  }

  static void close() => _faceDetector.close();
}