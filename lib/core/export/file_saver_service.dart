import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'file_saver_io.dart'
    if (dart.library.js_interop) 'file_saver_web.dart';

class FileSaverService {
  FileSaverService._();

  /// Formats byte count into closest human-readable unit (e.g. 2.0 KB, 1.4 MB, 1.2 GB)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024.0;
      return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024.0 * 1024.0);
      return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
    } else {
      final gb = bytes / (1024.0 * 1024.0 * 1024.0);
      return '${gb.toStringAsFixed(1)} GB';
    }
  }

  /// Saves or triggers a real browser/device file download for given bytes.
  static Future<bool> saveFile({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) => saveFilePlatform(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
  );

  /// Opens the native system Share Sheet (Android Share Chooser, iOS Share Sheet)
  /// allowing sharing directly to any installed app (WhatsApp, Drive, Gmail, etc.)
  static Future<bool> shareFile({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? subject,
    String? text,
  }) async {
    try {
      final xFile = XFile.fromData(
        bytes,
        name: filename,
        mimeType: mimeType,
      );
      // ignore: deprecated_member_use
      final result = await Share.shareXFiles(
        [xFile],
        subject: subject ?? filename,
        text: text ?? 'Shared from Forma Studio',
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return await saveFile(
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      );
    }
  }
}
