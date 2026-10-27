import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<bool> saveFilePlatform({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  try {
    final uri = await FilePicker.saveFile(
      fileName: filename,
      bytes: bytes,
      mimeType: mimeType,
    );
    return uri != null;
  } catch (_) {
    return false;
  }
}
