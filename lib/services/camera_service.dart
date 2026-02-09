import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  CameraController? get controller => _controller;

  CameraDescription? _cameraDescription;
  CameraDescription? get cameraDescription => _cameraDescription;

  Future<void> initializeCamera({
    ResolutionPreset resolutionPreset = ResolutionPreset.medium,
    CameraLensDirection cameraLensDirection = CameraLensDirection.front,
  }) async {
    final cameras = await availableCameras();
    _cameraDescription = cameras.firstWhere(
      (c) => c.lensDirection == cameraLensDirection,
      orElse: () => cameras.first,
    );

    final ImageFormatGroup imageFormatGroup = Platform.isAndroid
        ? ImageFormatGroup.yuv420
        : ImageFormatGroup.bgra8888;

    _controller = CameraController(
      _cameraDescription!,
      resolutionPreset,
      enableAudio: false,
      imageFormatGroup: imageFormatGroup,
    );

    await _controller!.initialize();
  }

  void startImageStream(Function(CameraImage) onImageStream) {
    if (_controller != null && !_controller!.value.isStreamingImages) {
      _controller!.startImageStream(onImageStream);
    }
  }

  void stopImageStream() {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        _controller!.stopImageStream();
      } catch (e) {
        // Tangani error jika stream sudah berhenti atau controller sudah di-dispose
        debugPrint("Error stopping image stream: $e");
      }
    }
  }

  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint("Error: Camera not initialized.");
      return null;
    }
    if (_controller!.value.isTakingPicture) {
      debugPrint("Already taking a picture.");
      return null;
    }
    try {
      return await _controller!.takePicture();
    } catch (e) {
      debugPrint("Error taking picture: $e");
      return null;
    }
  }

  void dispose() {
    stopImageStream();
    _controller?.dispose();
  }
}
