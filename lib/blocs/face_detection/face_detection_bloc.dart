import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gunas_employee_attendance/services/camera_service.dart';
import 'package:gunas_employee_attendance/services/face_data_service.dart';
import 'package:meta/meta.dart';

part 'face_detection_event.dart';
part 'face_detection_state.dart';

class FaceDetectionBloc extends Bloc<FaceDetectionEvent, FaceDetectionState> {
  final CameraService cameraService;
  final FaceDataService faceDataService;

  FaceDetectionBloc(this.cameraService, this.faceDataService)
    : super(FaceDetectionInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<CaptureAndRegisterFace>(_onCaptureAndRegisterFace);
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<FaceDetectionState> emit,
  ) async {
    emit(CameraInitializing());
    try {
      await cameraService.initializeCamera(); // <-- PERBAIKAN DI SINI
      emit(CameraReady());
    } catch (e) {
      emit(FaceCaptureFailure('Gagal menginisialisasi kamera: $e'));
    }
  }

  Future<void> _onCaptureAndRegisterFace(
    CaptureAndRegisterFace event,
    Emitter<FaceDetectionState> emit,
  ) async {
    emit(FaceCaptureInProgress());
    try {
      // 1. Capture the image using the camera service
      final image = await cameraService.takePicture();
      if (image == null) {
        emit(FaceCaptureFailure('Gagal mengambil gambar.'));
        return;
      }

      // 2. Delegate the registration process to FaceDataService
      final localPath = await faceDataService.registerFace(image);

      if (localPath == null) {
        emit(FaceCaptureFailure('Gagal mendaftarkan wajah.'));
        return;
      }

      // 3. Emit success state with the local path
      emit(FaceCaptureSuccess(localPath));
    } catch (e) {
      emit(FaceCaptureFailure('Terjadi kesalahan: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    cameraService.dispose();
    return super.close();
  }
}
