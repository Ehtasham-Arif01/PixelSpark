import 'dart:typed_data';

class AppConstants {
  // App info
  static const String appName    = 'PixelSpark';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Professional Photo Editor';

  // ML
  static const String mirnetPath = 'assets/models/enhancer.tflite';
  static const int    mirnetSize = 400;

  // History
  static const int maxHistory = 20;

  // Storage
  static const String saveFolder = 'PixelSpark';

  // Animation durations
  static const Duration fastAnim   = Duration(milliseconds: 200);
  static const Duration normalAnim = Duration(milliseconds: 350);
  static const Duration slowAnim   = Duration(milliseconds: 600);
  static const Duration splashDur  = Duration(milliseconds: 2800);

  // Brightness
  static const double brightnessDefault = 0.0;
  static const double brightnessMin     = -100.0;
  static const double brightnessMax     = 100.0;

  // Contrast
  static const double contrastDefault = 0.0;
  static const double contrastMin     = -100.0;
  static const double contrastMax     = 100.0;

  // Saturation
  static const double saturationDefault = 1.0;
  static const double saturationMin     = 0.0;
  static const double saturationMax     = 2.0;

  // Sharpen
  static const double sharpenDefault = 0.0;
  static const double sharpenMin     = 0.0;
  static const double sharpenMax     = 3.0;

  // Gamma
  static const double gammaDefault = 1.0;
  static const double gammaMin     = 0.5;
  static const double gammaMax     = 2.0;
}

// ── Filter definitions ────────────────────────────────────────────────────────

class FilterDef {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Future<Uint8List> Function(Uint8List) apply;

  const FilterDef({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.apply,
  });
}

// ── Tool friendly names ───────────────────────────────────────────────────────

enum AdjustTool {
  brightness,
  contrast,
  saturation,
  sharpen,
  gamma,
}

extension AdjustToolLabel on AdjustTool {
  String get label {
    switch (this) {
      case AdjustTool.brightness: return 'Brightness';
      case AdjustTool.contrast:   return 'Contrast';
      case AdjustTool.saturation: return 'Vibrance';
      case AdjustTool.sharpen:    return 'Sharpness';
      case AdjustTool.gamma:      return 'Exposure';
    }
  }
}
