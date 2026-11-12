import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionDataSource {
  final _detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast, minFaceSize: 0.15),
  );

  Future<int> countInFile(String path) async =>
      (await _detector.processImage(InputImage.fromFilePath(path))).length;

  Future<int?> countInFrame(CameraImage image, CameraDescription camera) async {
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final raw = image.format.raw;
    final format = raw is int ? InputImageFormatValue.fromRawValue(raw) : null;
    if (rotation == null || format == null || image.planes.length != 1) return null;
    final supported = Platform.isAndroid ? format == InputImageFormat.nv21 : format == InputImageFormat.bgra8888;
    if (!supported) return null;

    final plane = image.planes.first;
    final input = InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
    return (await _detector.processImage(input)).length;
  }

  Future<void> close() => _detector.close();
}
