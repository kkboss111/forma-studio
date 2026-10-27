import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FormaThemeMode {
  system,
  light,
  dark,
  liquidGlass,
}

enum SidebarSide {
  left,
  right,
}

enum CardDensity {
  compact,
  normal,
  spacious,
}

class ResolutionPreset {
  final String name;
  final double width;
  final double height;
  final String category;

  const ResolutionPreset({
    required this.name,
    required this.width,
    required this.height,
    required this.category,
  });

  String get label => '$name (${width.toInt()} × ${height.toInt()})';

  static const List<ResolutionPreset> presets = [
    ResolutionPreset(
      name: 'Mobile Standard (9:19.5)',
      width: 393,
      height: 852,
      category: 'Mobile',
    ),
    ResolutionPreset(
      name: 'Mobile Large (9:19.5)',
      width: 430,
      height: 932,
      category: 'Mobile',
    ),
    ResolutionPreset(
      name: 'Mobile Tall (9:20)',
      width: 412,
      height: 923,
      category: 'Mobile',
    ),
    ResolutionPreset(
      name: 'Mobile Wide (9:20)',
      width: 412,
      height: 915,
      category: 'Mobile',
    ),
    ResolutionPreset(
      name: 'Tablet Portrait (3:4)',
      width: 834,
      height: 1194,
      category: 'Tablet',
    ),
    ResolutionPreset(
      name: 'Tablet Large (3:4)',
      width: 1024,
      height: 1366,
      category: 'Tablet',
    ),
    ResolutionPreset(
      name: 'Laptop Standard (16:10)',
      width: 1512,
      height: 982,
      category: 'Desktop',
    ),
    ResolutionPreset(
      name: 'Desktop FHD (16:9)',
      width: 1920,
      height: 1080,
      category: 'Desktop',
    ),
    ResolutionPreset(
      name: 'Desktop 4K UHD (16:9)',
      width: 3840,
      height: 2160,
      category: 'Desktop',
    ),
    ResolutionPreset(
      name: 'Square Format (1:1)',
      width: 1080,
      height: 1080,
      category: 'Social',
    ),
  ];
}

class AppSettings {
  final FormaThemeMode themeMode;
  final double glassBlur; // 5.0 to 60.0
  final double glassOpacity; // 0.15 to 0.85
  final bool glassSpecular;
  final bool glassSheen;
  final bool snapToGrid;
  final bool snapToObjects;
  final double defaultGridSize;
  final bool showRulers;
  final bool showGrid;
  final bool highRefreshRate;
  final bool reduceBlurForPerformance;
  final int autoSaveIntervalMs;
  final SidebarSide sidebarPrimarySide;
  final CardDensity cardDensity;
  final String? lockedResolutionPreset;
  final bool haveUserStartedApp;
  final bool enableHtmlCodeExport;

  const AppSettings({
    this.themeMode = FormaThemeMode.system,
    this.glassBlur = 32.0,
    this.glassOpacity = 0.45,
    this.glassSpecular = true,
    this.glassSheen = true,
    this.snapToGrid = true,
    this.snapToObjects = true,
    this.defaultGridSize = 16.0,
    this.showRulers = true,
    this.showGrid = true,
    this.highRefreshRate = true,
    this.reduceBlurForPerformance = false,
    this.autoSaveIntervalMs = 600,
    this.sidebarPrimarySide = SidebarSide.left,
    this.cardDensity = CardDensity.compact,
    this.lockedResolutionPreset,
    this.haveUserStartedApp = false,
    this.enableHtmlCodeExport = false,
  });

  AppSettings copyWith({
    FormaThemeMode? themeMode,
    double? glassBlur,
    double? glassOpacity,
    bool? glassSpecular,
    bool? glassSheen,
    bool? snapToGrid,
    bool? snapToObjects,
    double? defaultGridSize,
    bool? showRulers,
    bool? showGrid,
    bool? highRefreshRate,
    bool? reduceBlurForPerformance,
    int? autoSaveIntervalMs,
    SidebarSide? sidebarPrimarySide,
    CardDensity? cardDensity,
    String? lockedResolutionPreset,
    bool clearResolutionPreset = false,
    bool? haveUserStartedApp,
    bool? enableHtmlCodeExport,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      glassBlur: glassBlur ?? this.glassBlur,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      glassSpecular: glassSpecular ?? this.glassSpecular,
      glassSheen: glassSheen ?? this.glassSheen,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      snapToObjects: snapToObjects ?? this.snapToObjects,
      defaultGridSize: defaultGridSize ?? this.defaultGridSize,
      showRulers: showRulers ?? this.showRulers,
      showGrid: showGrid ?? this.showGrid,
      highRefreshRate: highRefreshRate ?? this.highRefreshRate,
      reduceBlurForPerformance:
          reduceBlurForPerformance ?? this.reduceBlurForPerformance,
      autoSaveIntervalMs: autoSaveIntervalMs ?? this.autoSaveIntervalMs,
      sidebarPrimarySide: sidebarPrimarySide ?? this.sidebarPrimarySide,
      cardDensity: cardDensity ?? this.cardDensity,
      lockedResolutionPreset: clearResolutionPreset
          ? null
          : (lockedResolutionPreset ?? this.lockedResolutionPreset),
      haveUserStartedApp: haveUserStartedApp ?? this.haveUserStartedApp,
      enableHtmlCodeExport: enableHtmlCodeExport ?? this.enableHtmlCodeExport,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'glassBlur': glassBlur,
    'glassOpacity': glassOpacity,
    'glassSpecular': glassSpecular,
    'glassSheen': glassSheen,
    'snapToGrid': snapToGrid,
    'snapToObjects': snapToObjects,
    'defaultGridSize': defaultGridSize,
    'showRulers': showRulers,
    'showGrid': showGrid,
    'highRefreshRate': highRefreshRate,
    'reduceBlurForPerformance': reduceBlurForPerformance,
    'autoSaveIntervalMs': autoSaveIntervalMs,
    'sidebarPrimarySide': sidebarPrimarySide.name,
    'cardDensity': cardDensity.name,
    'lockedResolutionPreset': lockedResolutionPreset,
    'haveUserStartedApp': haveUserStartedApp,
    'enableHtmlCodeExport': enableHtmlCodeExport,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: FormaThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => FormaThemeMode.system,
      ),
      glassBlur: (json['glassBlur'] as num?)?.toDouble() ?? 32.0,
      glassOpacity: (json['glassOpacity'] as num?)?.toDouble() ?? 0.45,
      glassSpecular: json['glassSpecular'] as bool? ?? true,
      glassSheen: json['glassSheen'] as bool? ?? true,
      snapToGrid: json['snapToGrid'] as bool? ?? true,
      snapToObjects: json['snapToObjects'] as bool? ?? true,
      defaultGridSize: (json['defaultGridSize'] as num?)?.toDouble() ?? 16.0,
      showRulers: json['showRulers'] as bool? ?? true,
      showGrid: json['showGrid'] as bool? ?? true,
      highRefreshRate: json['highRefreshRate'] as bool? ?? true,
      reduceBlurForPerformance:
          json['reduceBlurForPerformance'] as bool? ?? false,
      autoSaveIntervalMs: json['autoSaveIntervalMs'] as int? ?? 600,
      sidebarPrimarySide: SidebarSide.values.firstWhere(
        (e) => e.name == json['sidebarPrimarySide'],
        orElse: () => SidebarSide.left,
      ),
      cardDensity: CardDensity.values.firstWhere(
        (e) => e.name == json['cardDensity'],
        orElse: () => CardDensity.compact,
      ),
      lockedResolutionPreset: json['lockedResolutionPreset'] as String?,
      haveUserStartedApp: json['haveUserStartedApp'] as bool? ?? false,
      enableHtmlCodeExport: json['enableHtmlCodeExport'] as bool? ?? false,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _prefsKey = 'forma_app_settings';

  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefsKey);
      if (str != null) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        state = AppSettings.fromJson(map);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings(AppSettings newSettings) async {
    state = newSettings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(newSettings.toJson()));
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  void setThemeMode(FormaThemeMode mode) =>
      _saveSettings(state.copyWith(themeMode: mode));

  void setGlassBlur(double blur) =>
      _saveSettings(state.copyWith(glassBlur: blur));

  void setGlassOpacity(double opacity) =>
      _saveSettings(state.copyWith(glassOpacity: opacity));

  void toggleGlassSpecular(bool val) =>
      _saveSettings(state.copyWith(glassSpecular: val));

  void toggleGlassSheen(bool val) =>
      _saveSettings(state.copyWith(glassSheen: val));

  void toggleSnapToGrid(bool val) =>
      _saveSettings(state.copyWith(snapToGrid: val));

  void toggleSnapToObjects(bool val) =>
      _saveSettings(state.copyWith(snapToObjects: val));

  void setDefaultGridSize(double size) =>
      _saveSettings(state.copyWith(defaultGridSize: size));

  void toggleShowRulers(bool val) =>
      _saveSettings(state.copyWith(showRulers: val));

  void toggleShowGrid(bool val) =>
      _saveSettings(state.copyWith(showGrid: val));

  void toggleReduceBlur(bool val) =>
      _saveSettings(state.copyWith(reduceBlurForPerformance: val));

  void setSidebarPrimarySide(SidebarSide side) =>
      _saveSettings(state.copyWith(sidebarPrimarySide: side));

  void setCardDensity(CardDensity density) =>
      _saveSettings(state.copyWith(cardDensity: density));

  void setLockedResolutionPreset(String? preset) {
    if (preset == null) {
      _saveSettings(state.copyWith(clearResolutionPreset: true));
    } else {
      _saveSettings(state.copyWith(lockedResolutionPreset: preset));
    }
  }

  void setHaveUserStartedApp(bool val) =>
      _saveSettings(state.copyWith(haveUserStartedApp: val));

  void setAutoSaveIntervalMs(int ms) =>
      _saveSettings(state.copyWith(autoSaveIntervalMs: ms));

  void toggleEnableHtmlCodeExport(bool val) =>
      _saveSettings(state.copyWith(enableHtmlCodeExport: val));

  void resetToDefaults() => _saveSettings(const AppSettings());
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);
