import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';

class LocalFileService {
  Future<String> get _localPath async {
    // Menemukan direktori penyimpanan dokumen pribadi aplikasi.
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> saveImage(XFile image, String userId) async {
    final path = await _localPath;
    final String fileName = '$userId.jpg';
    final File localImage = File('$path/$fileName');

    // Membaca bytes dari gambar yang diambil
    final imageBytes = await image.readAsBytes();

    // Menulis file ke penyimpanan lokal
    return localImage.writeAsBytes(imageBytes);
  }
}
