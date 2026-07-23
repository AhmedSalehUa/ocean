import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Thin wrapper over `file_picker` that pins the extension allow-list to
/// what the backend accepts for the delivery-note PATCH endpoint.
class FilePickService {
  const FilePickService();

  /// Extensions the delivery-note endpoint accepts, per the mobile-API spec.
  static const List<String> deliveryNoteExtensions = [
    'pdf',
    'xls',
    'xlsx',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  /// Opens the platform picker restricted to the delivery-note allow-list.
  /// Returns `null` if the user backs out of the picker.
  Future<File?> pickDeliveryNote() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: deliveryNoteExtensions,
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    return File(path);
  }

  /// Client-side validation so we don't waste a PATCH when the user
  /// picked something the server would reject. The file picker restricts
  /// extensions on iOS/Android but not on desktop, so we double-check.
  static bool isAllowedForDeliveryNote(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot >= fileName.length - 1) return false;
    final ext = fileName.substring(dot + 1).toLowerCase();
    return deliveryNoteExtensions.contains(ext);
  }
}
