part of 'face_detection_bloc.dart';

@immutable
sealed class FaceDetectionState {}

final class FaceDetectionInitial extends FaceDetectionState {}

final class CameraInitializing extends FaceDetectionState {}

final class CameraReady extends FaceDetectionState {}

final class FaceCaptureInProgress extends FaceDetectionState {}

final class FaceCaptureSuccess extends FaceDetectionState {
  final String imageUrl;

  FaceCaptureSuccess(this.imageUrl);
}

final class FaceCaptureFailure extends FaceDetectionState {
  final String error;

  FaceCaptureFailure(this.error);
}
