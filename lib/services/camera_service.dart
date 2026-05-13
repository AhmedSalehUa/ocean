import 'dart:io';

import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takePhoto() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 86,
    );
    return xfile == null ? null : File(xfile.path);
  }

  Future<File?> pickFromGallery() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 86);
    return xfile == null ? null : File(xfile.path);
  }
}
