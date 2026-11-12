import 'dart:async';
import 'dart:io';

import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/features/attendance/di/attendance_providers.dart';
import 'package:c360/features/attendance/presentation/providers/check_controller.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class SelfieCamera extends ConsumerStatefulWidget {
  const SelfieCamera({super.key, required this.title, required this.onCaptured, required this.onCancel, this.error});

  final String title;
  final String? error;
  final ValueChanged<String> onCaptured;
  final VoidCallback onCancel;

  @override
  ConsumerState<SelfieCamera> createState() => _SelfieCameraState();
}

class _SelfieCameraState extends ConsumerState<SelfieCamera> with WidgetsBindingObserver {
  late final _faces = ref.read(faceDetectionProvider);
  CameraController? _controller;
  CameraDescription? _camera;
  String? _issue;
  var _blocked = false;
  var _faceCount = 0;
  var _detecting = false;
  var _capturing = false;
  var _starting = false;
  var _lastFrame = DateTime(0);
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void didUpdateWidget(SelfieCamera old) {
    super.didUpdateWidget(old);
    if (widget.error != old.error && widget.error != null) _localError = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      unawaited(_stop());
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      unawaited(_start());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stop());
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting) return;
    _starting = true;
    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        _blocked = status.isPermanentlyDenied || status.isRestricted;
        setState(() => _issue = _blocked
            ? 'Camera access is off for C360 Field. Allow it in Settings to take your attendance photo.'
            : 'Allow camera access to take your attendance photo.');
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('none', 'No camera');
      final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = front;
      _controller = controller;
      await controller.startImageStream(_onFrame);
      setState(() {
        _issue = null;
        _faceCount = 0;
      });
    } on CameraException {
      if (mounted) {
        setState(() => _issue = 'The camera isn’t available right now. Close other camera apps and try again.');
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> _stop() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) await controller.stopImageStream();
    } catch (_) {}
    await controller.dispose();
  }

  void _onFrame(CameraImage image) {
    final camera = _camera;
    final now = DateTime.now();
    if (camera == null || _detecting || _capturing || now.difference(_lastFrame).inMilliseconds < 300) return;
    _lastFrame = now;
    _detecting = true;
    _faces
        .countInFrame(image, camera)
        .then((count) {
          if (mounted && count != null && count != _faceCount) setState(() => _faceCount = count);
        })
        .catchError((Object _) {})
        .whenComplete(() => _detecting = false);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing || _faceCount != 1) return;
    setState(() {
      _capturing = true;
      _localError = null;
    });
    unawaited(HapticFeedback.mediumImpact());

    try {
      if (controller.value.isStreamingImages) await controller.stopImageStream();
      for (var i = 0; i < 20 && _detecting; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      final photo = await controller.takePicture();
      final count = await _faces.countInFile(photo.path);
      if (!mounted) return;
      if (count == 1) return widget.onCaptured(photo.path);

      await File(photo.path).delete().catchError((Object _) => File(photo.path));
      setState(() {
        _localError = count == 0 ? CheckController.noFaceMessage : 'Only one person should be in the photo.';
        _faceCount = 0;
        _capturing = false;
      });
      await controller.startImageStream(_onFrame);
    } on CameraException {
      if (!mounted) return;
      setState(() {
        _localError = 'Couldn’t take the photo. Try again.';
        _capturing = false;
      });
      if (!controller.value.isStreamingImages) await controller.startImageStream(_onFrame);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _localError ?? widget.error;
    final ready = _faceCount == 1 && !_capturing && _controller != null;
    final hint = error ??
        switch (_faceCount) {
          0 => 'Fit your face inside the oval. Remove sunglasses and lift your visor.',
          1 => 'Looks good. Hold still and take the photo.',
          _ => 'Only one person should be in the frame.',
        };
    final controller = _controller;
    final previewSize = controller?.value.previewSize;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Brand.camera,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: widget.onCancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                    Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _issue != null
                    ? Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              _issue!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _blocked ? openAppSettings : _start,
                              child: Text(_blocked ? 'Open Settings' : 'Try again'),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          if (controller != null && controller.value.isInitialized && previewSize != null)
                            ClipRect(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: previewSize.height,
                                  height: previewSize.width,
                                  child: CameraPreview(controller),
                                ),
                              ),
                            )
                          else
                            const Center(child: CircularProgressIndicator(color: Colors.white70)),
                          CustomPaint(painter: _OvalPainter(ready ? context.palette.success : Brand.gold)),
                        ],
                      ),
              ),
              if (_issue == null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: error != null ? context.palette.destructive : const Color(0xE6FFFFFF),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Semantics(
                    button: true,
                    enabled: ready,
                    label: 'Take photo',
                    child: GestureDetector(
                      onTap: ready ? _capture : null,
                      child: Opacity(
                        opacity: ready || _capturing ? 1 : 0.4,
                        child: Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: DecoratedBox(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: _capturing
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Brand.camera),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OvalPainter extends CustomPainter {
  _OvalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * 0.68;
    final oval = Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.46), width: width, height: width * 1.3);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addOval(oval),
      Paint()..color = const Color(0x8C000000),
    );
    canvas.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_OvalPainter old) => old.color != color;
}
