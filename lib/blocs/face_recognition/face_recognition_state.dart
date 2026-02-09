part of 'face_recognition_bloc.dart';

@immutable
sealed class FaceRecognitionState {}

final class FaceRecognitionInitial extends FaceRecognitionState {}

final class FaceRecognitionLoading extends FaceRecognitionState {}

final class FaceMatched extends FaceRecognitionState {
  final double confidence;
  FaceMatched(this.confidence);
}

final class FaceNotMatched extends FaceRecognitionState {}

final class FaceRecognitionFailure extends FaceRecognitionState {
  final String error;
  FaceRecognitionFailure(this.error);
}
