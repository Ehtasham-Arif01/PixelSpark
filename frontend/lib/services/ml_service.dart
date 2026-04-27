import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../constants/app_constants.dart';
import 'native_processor.dart';

// ── Payload classes (top-level) ───────────────────────────────────────────────

class _MirnetPayload {
  final String modelPath;
  final Uint8List bytes;
  final int size;

  const _MirnetPayload({
    required this.modelPath,
    required this.bytes,
    required this.size,
  });
}

class _BlendPayload {
  final Uint8List original;
  final Uint8List enhanced;
  final double strength;

  const _BlendPayload(this.original, this.enhanced, this.strength);
}

// ── Top-level isolate: MIRNet inference ──────────────────────────────────────

Future<Uint8List> _mirnetIsolate(_MirnetPayload p) async {
  // 1. Decode bytes → img.Image
  var decoded = img.decodeImage(p.bytes);
  if (decoded == null) throw StateError('Cannot decode input image.');

  // Pre-resize for performance: limit to max 800px longest side
  if (decoded.width > 800 || decoded.height > 800) {
    decoded = img.copyResize(
      decoded,
      width: decoded.width > decoded.height ? 800 : null,
      height: decoded.height >= decoded.width ? 800 : null,
      interpolation: img.Interpolation.linear,
    );
  }

  final originalWidth  = decoded.width;
  final originalHeight = decoded.height;
  final targetSize     = p.size;

  // 2. Letterbox resize to targetSize × targetSize
  final scale         = originalWidth > originalHeight
      ? targetSize / originalWidth
      : targetSize / originalHeight;
  final contentWidth  = (originalWidth  * scale).round().clamp(1, targetSize);
  final contentHeight = (originalHeight * scale).round().clamp(1, targetSize);
  final offsetX       = ((targetSize - contentWidth)  / 2).round();
  final offsetY       = ((targetSize - contentHeight) / 2).round();

  final resized = img.copyResize(
    decoded,
    width: contentWidth,
    height: contentHeight,
    interpolation: img.Interpolation.average,
  );

  final canvas = img.Image(width: targetSize, height: targetSize, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(0, 0, 0));
  img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);

  // 3. Normalize to float32 [1, size, size, 3]
  final input = List.generate(
    1,
    (_) => List.generate(
      targetSize,
      (y) => List.generate(
        targetSize,
        (x) {
          final pix = canvas.getPixel(x, y);
          return [pix.r / 255.0, pix.g / 255.0, pix.b / 255.0];
        },
      ),
    ),
  );

  final output = List.generate(
    1,
    (_) => List.generate(
      targetSize,
      (_) => List.generate(targetSize, (_) => [0.0, 0.0, 0.0]),
    ),
  );

  // 4. Load interpreter inside isolate and run inference
  final interpreter = Interpreter.fromFile(File(p.modelPath));
  try {
    interpreter.run(input, output);
  } finally {
    interpreter.close();
  }

  // 5. Denormalize output
  final enhancedBox = img.Image(width: targetSize, height: targetSize, numChannels: 3);
  for (int y = 0; y < targetSize; y++) {
    for (int x = 0; x < targetSize; x++) {
      final rgb = output[0][y][x];
      final r = (rgb[0] * 255.0).round().clamp(0, 255);
      final g = (rgb[1] * 255.0).round().clamp(0, 255);
      final b = (rgb[2] * 255.0).round().clamp(0, 255);
      enhancedBox.setPixelRgb(x, y, r, g, b);
    }
  }

  // 6. Crop letterbox padding and resize back to original dimensions
  final cropped = img.copyCrop(
    enhancedBox,
    x: offsetX,
    y: offsetY,
    width: contentWidth,
    height: contentHeight,
  );

  final restored = img.copyResize(
    cropped,
    width: originalWidth,
    height: originalHeight,
    interpolation: img.Interpolation.cubic,
  );

  return Uint8List.fromList(img.encodePng(restored));
}

// ── Top-level isolate: pixel blend ────────────────────────────────────────────

Uint8List _blendIsolate(_BlendPayload p) {
  final original = img.decodeImage(p.original);
  final enhanced = img.decodeImage(p.enhanced);
  if (original == null || enhanced == null) {
    throw StateError('Invalid bytes for blending.');
  }

  final alignedEnhanced = (original.width == enhanced.width &&
          original.height == enhanced.height)
      ? enhanced
      : img.copyResize(
          enhanced,
          width: original.width,
          height: original.height,
          interpolation: img.Interpolation.cubic,
        );

  final out = img.Image(
    width: original.width,
    height: original.height,
    numChannels: 4,
  );
  final s   = p.strength;
  final inv = 1.0 - s;

  for (int y = 0; y < original.height; y++) {
    for (int x = 0; x < original.width; x++) {
      final o = original.getPixel(x, y);
      final e = alignedEnhanced.getPixel(x, y);
      final r = (e.r * s + o.r * inv).round().clamp(0, 255);
      final g = (e.g * s + o.g * inv).round().clamp(0, 255);
      final b = (e.b * s + o.b * inv).round().clamp(0, 255);
      final a = (e.a * s + o.a * inv).round().clamp(0, 255);
      out.setPixelRgba(x, y, r, g, b, a);
    }
  }

  return Uint8List.fromList(img.encodePng(out));
}

// ── MLService ─────────────────────────────────────────────────────────────────

class MLService {
  Interpreter? _interpreter;
  bool _isLoaded = false;
  String? _modelPath;

  Future<void> loadModel() async {
    try {
      _interpreter?.close();
      final opts = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        AppConstants.mirnetPath,
        options: opts,
      );

      // Copy model to temp dir so isolate can load it from a file path
      final modelBytes = await rootBundle.load(AppConstants.mirnetPath);
      final dir        = await getTemporaryDirectory();
      final modelFile  = File('${dir.path}/enhancer.tflite');
      await modelFile.writeAsBytes(
        modelBytes.buffer.asUint8List(),
        flush: true,
      );
      _modelPath = modelFile.path;
      _isLoaded  = true;

      debugPrint('[ML] MIRNet loaded ✓');
      debugPrint('[ML] Input:  ${_interpreter!.getInputTensor(0).shape}');
      debugPrint('[ML] Output: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      _interpreter?.close();
      _interpreter = null;
      _modelPath   = null;
      _isLoaded    = false;
      debugPrint('[ML] Model not found → C++ fallback: $e');
    }
  }

  Future<Uint8List> enhance(Uint8List input) async {
    if (!_isLoaded || _modelPath == null) return _cppFallback(input);
    try {
      return await compute(
        _mirnetIsolate,
        _MirnetPayload(
          modelPath: _modelPath!,
          bytes:     input,
          size:      AppConstants.mirnetSize,
        ),
      );
    } catch (e) {
      debugPrint('[ML] Inference error: $e');
      return _cppFallback(input);
    }
  }

  Future<Uint8List> blend(
    Uint8List original,
    Uint8List enhanced,
    double strength,
  ) async {
    final s = strength.clamp(0.0, 1.0);
    return compute(_blendIsolate, _BlendPayload(original, enhanced, s));
  }

  Future<Uint8List> _cppFallback(Uint8List b) async {
    var r = await NativeProcessor.enhanceDetails(b);
    r = await NativeProcessor.adjustBrightness(r, 10);
    r = await NativeProcessor.adjustContrast(r, 15);
    r = await NativeProcessor.applySharpen(r, 0.5);
    return r;
  }

  bool get isLoaded => _isLoaded;

  void dispose() => _interpreter?.close();
}
