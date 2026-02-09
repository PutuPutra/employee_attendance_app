part of 'face_detection_bloc.dart';

@immutable
sealed class FaceDetectionEvent {}

/// Event to initialize the camera service.
final class InitializeCamera extends FaceDetectionEvent {}

/// Event to trigger face capture and registration process.
final class CaptureAndRegisterFace extends FaceDetectionEvent {}
