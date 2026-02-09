part of 'face_recognition_bloc.dart';

@immutable
sealed class FaceRecognitionEvent {}

class LoadRegisteredFace extends FaceRecognitionEvent {}

class ProcessCameraImage extends FaceRecognitionEvent {
  final CameraImage image;
  final CameraDescription cameraDescription;

  ProcessCameraImage(this.image, this.cameraDescription);
}
