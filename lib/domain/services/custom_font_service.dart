import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing custom imported font files (.ttf, .otf, .woff) into the Flutter engine at runtime,
/// with full local offline persistence across restarts.
class CustomFontService {
  CustomFontService._();

  static const String _storageKey = 'forma_offline_custom_fonts';
  static final List<String> _importedFonts = [];
  static final Map<String, Uint8List> _fontByteStore = {};
  static bool _isInitialized = false;

  /// Returns unmodifiable list of all currently loaded custom font family names.
  static List<String> get importedFonts => List.unmodifiable(_importedFonts);

  /// Whether a specific font family is already loaded.
  static bool isImported(String familyName) => _importedFonts.contains(familyName);

  /// Initializes and loads all offline persisted fonts from local storage into Flutter's FontLoader.
  /// Call this during app startup or when accessing custom typography.
  static Future<void> initializeOfflineFonts() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      for (final jsonStr in rawList) {
        try {
          final data = json.decode(jsonStr) as Map<String, dynamic>;
          final name = data['name'] as String?;
          final b64 = data['bytes'] as String?;
          if (name != null && b64 != null && name.isNotEmpty) {
            final bytes = base64.decode(b64);
            await loadFontFromBytes(
              familyName: name,
              fontBytes: bytes,
              persist: false,
            );
          }
        } catch (_) {}
      }
      _isInitialized = true;
    } catch (_) {}
  }

  /// Opens the device/system file picker for local `.ttf`, `.otf`, `.woff`, `.woff2` font files,
  /// registers the font into Flutter's engine, and persists it locally for offline use.
  static Future<String?> pickAndImportFontFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf', 'woff', 'woff2'],
      );

      if (file == null) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      // Clean font family name from file name
      final rawName = file.name
          .replaceAll(RegExp(r'\.(ttf|otf|woff2?)$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[-_]'), ' ')
          .trim();
      final familyName = rawName.isNotEmpty ? rawName : 'CustomFont_${DateTime.now().millisecondsSinceEpoch % 1000}';

      final success = await loadFontFromBytes(
        familyName: familyName,
        fontBytes: bytes,
        persist: true,
      );

      return success ? familyName : null;
    } catch (_) {
      return null;
    }
  }

  /// Loads a font from binary data into the Flutter engine's [FontLoader]
  /// and optionally persists it into local storage.
  static Future<bool> loadFontFromBytes({
    required String familyName,
    required Uint8List fontBytes,
    bool persist = true,
  }) async {
    final cleanName = familyName.trim();
    if (cleanName.isEmpty || fontBytes.isEmpty) return false;

    try {
      final loader = FontLoader(cleanName);
      loader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
      await loader.load();

      if (!_importedFonts.contains(cleanName)) {
        _importedFonts.add(cleanName);
      }
      _fontByteStore[cleanName] = fontBytes;

      if (persist) {
        await _persistFont(cleanName, fontBytes);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes an imported font from memory and local storage.
  static Future<void> removeFont(String familyName) async {
    _importedFonts.remove(familyName);
    _fontByteStore.remove(familyName);

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      rawList.removeWhere((item) {
        try {
          final data = json.decode(item) as Map<String, dynamic>;
          return data['name'] == familyName;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_storageKey, rawList);
    } catch (_) {}
  }

  /// Saves font name and base64 bytes to SharedPreferences.
  static Future<void> _persistFont(String name, Uint8List bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];

      // Avoid duplicates
      rawList.removeWhere((item) {
        try {
          final data = json.decode(item) as Map<String, dynamic>;
          return data['name'] == name;
        } catch (_) {
          return false;
        }
      });

      final entry = json.encode({
        'name': name,
        'bytes': base64.encode(bytes),
      });
      rawList.add(entry);
      await prefs.setStringList(_storageKey, rawList);
    } catch (_) {}
  }
}
