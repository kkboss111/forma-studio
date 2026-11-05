import 'package:flutter/services.dart';

/// Service managing custom imported font files (.ttf, .otf) into the Flutter engine at runtime.
class CustomFontService {
  CustomFontService._();

  static final List<String> _importedFonts = [];
  static final Map<String, Uint8List> _fontByteStore = {};

  static List<String> get importedFonts => List.unmodifiable(_importedFonts);

  static bool isImported(String familyName) => _importedFonts.contains(familyName);

  /// Loads a font from binary data into the Flutter engine's FontLoader
  static Future<bool> loadFontFromBytes({
    required String familyName,
    required Uint8List fontBytes,
  }) async {
    final cleanName = familyName.trim();
    if (cleanName.isEmpty) return false;

    try {
      final loader = FontLoader(cleanName);
      loader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
      await loader.load();

      if (!_importedFonts.contains(cleanName)) {
        _importedFonts.add(cleanName);
      }
      _fontByteStore[cleanName] = fontBytes;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes an imported font reference
  static void removeFont(String familyName) {
    _importedFonts.remove(familyName);
    _fontByteStore.remove(familyName);
  }
}
