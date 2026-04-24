import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as img;

// ─── Native function typedefs ────────────────────────────────────────────────

typedef _SimpleNative = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, Int32 w, Int32 h, Pointer<Int32> outSize);
typedef _SimpleDart = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, int w, int h, Pointer<Int32> outSize);

typedef _FloatParamNative = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, Int32 w, Int32 h, Float param, Pointer<Int32> outSize);
typedef _FloatParamDart = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, int w, int h, double param, Pointer<Int32> outSize);

typedef _IntParamNative = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, Int32 w, Int32 h, Int32 param, Pointer<Int32> outSize);
typedef _IntParamDart = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, int w, int h, int param, Pointer<Int32> outSize);

typedef _CannyNative = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, Int32 w, Int32 h, Int32 t1, Int32 t2, Pointer<Int32> outSize);
typedef _CannyDart = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, int w, int h, int t1, int t2, Pointer<Int32> outSize);

typedef _RotateNative = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, Int32 w, Int32 h,
    Float angle, Pointer<Int32> outW, Pointer<Int32> outH, Pointer<Int32> outSize);
typedef _RotateDart = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, int w, int h,
    double angle, Pointer<Int32> outW, Pointer<Int32> outH, Pointer<Int32> outSize);

typedef _FlipNative = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, Int32 w, Int32 h, Int32 direction, Pointer<Int32> outSize);
typedef _FlipDart = Pointer<Uint8> Function(
    Pointer<Uint8> rgba, int w, int h, int direction, Pointer<Int32> outSize);

typedef _FreeNative = Void Function(Pointer<Uint8>);
typedef _FreeDart  = void Function(Pointer<Uint8>);

// ─── Library loader ──────────────────────────────────────────────────────────

DynamicLibrary _openLib() {
  if (Platform.isAndroid) return DynamicLibrary.open('libimage_processor.so');
  if (Platform.isLinux)   return DynamicLibrary.open('libimage_processor.so');
  if (Platform.isMacOS)   return DynamicLibrary.open('libimage_processor.dylib');
  if (Platform.isWindows) return DynamicLibrary.open('image_processor.dll');
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

// ─── Image encode/decode helpers ─────────────────────────────────────────────

/// Decode any image format to raw RGBA bytes.
({Uint8List rgba, int width, int height}) _decode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes)!;
  final rgba = Uint8List(decoded.width * decoded.height * 4);
  int i = 0;
  for (int y = 0; y < decoded.height; y++) {
    for (int x = 0; x < decoded.width; x++) {
      final p = decoded.getPixel(x, y);
      rgba[i++] = p.r.toInt();
      rgba[i++] = p.g.toInt();
      rgba[i++] = p.b.toInt();
      rgba[i++] = p.a.toInt();
    }
  }
  return (rgba: rgba, width: decoded.width, height: decoded.height);
}

/// Encode raw RGBA to PNG.
Uint8List _encodePng(Uint8List rgba, int width, int height) {
  final image = img.Image.fromBytes(
    width: width, height: height,
    bytes: rgba.buffer, numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return Uint8List.fromList(img.encodePng(image));
}

/// Copy Dart Uint8List to FFI memory, process, copy result back, free C buffer.
Uint8List _callSimple(Uint8List rgba, int w, int h, String fn) {
  final lib  = _openLib();
  final call = lib.lookupFunction<_SimpleNative, _SimpleDart>(fn);
  final free = lib.lookupFunction<_FreeNative,  _FreeDart>('free_result');

  final inPtr  = malloc.allocate<Uint8>(rgba.length);
  inPtr.asTypedList(rgba.length).setAll(0, rgba);
  final szPtr  = malloc.allocate<Int32>(1);

  final result = call(inPtr, w, h, szPtr);
  final sz     = szPtr.value;
  malloc.free(inPtr);
  malloc.free(szPtr);

  if (result == nullptr || sz <= 0) throw Exception('$fn returned null');
  final out = Uint8List.fromList(result.asTypedList(sz));
  free(result);
  return out;
}

Uint8List _callFloat(Uint8List rgba, int w, int h, String fn, double param) {
  final lib  = _openLib();
  final call = lib.lookupFunction<_FloatParamNative, _FloatParamDart>(fn);
  final free = lib.lookupFunction<_FreeNative, _FreeDart>('free_result');

  final inPtr = malloc.allocate<Uint8>(rgba.length);
  inPtr.asTypedList(rgba.length).setAll(0, rgba);
  final szPtr = malloc.allocate<Int32>(1);

  final result = call(inPtr, w, h, param, szPtr);
  final sz     = szPtr.value;
  malloc.free(inPtr);
  malloc.free(szPtr);

  if (result == nullptr || sz <= 0) throw Exception('$fn returned null');
  final out = Uint8List.fromList(result.asTypedList(sz));
  free(result);
  return out;
}

Uint8List _callInt(Uint8List rgba, int w, int h, String fn, int param) {
  final lib  = _openLib();
  final call = lib.lookupFunction<_IntParamNative, _IntParamDart>(fn);
  final free = lib.lookupFunction<_FreeNative, _FreeDart>('free_result');

  final inPtr = malloc.allocate<Uint8>(rgba.length);
  inPtr.asTypedList(rgba.length).setAll(0, rgba);
  final szPtr = malloc.allocate<Int32>(1);

  final result = call(inPtr, w, h, param, szPtr);
  final sz     = szPtr.value;
  malloc.free(inPtr);
  malloc.free(szPtr);

  if (result == nullptr || sz <= 0) throw Exception('$fn returned null');
  final out = Uint8List.fromList(result.asTypedList(sz));
  free(result);
  return out;
}

// ─── Isolate entry points (top-level so compute() can find them) ─────────────

Uint8List _isoSimple(({Uint8List img, int w, int h, String fn}) args) {
  final raw = _callSimple(args.img, args.w, args.h, args.fn);
  return _encodePng(raw, args.w, args.h);
}

Uint8List _isoFloat(({Uint8List img, int w, int h, String fn, double p}) args) {
  final raw = _callFloat(args.img, args.w, args.h, args.fn, args.p);
  return _encodePng(raw, args.w, args.h);
}

Uint8List _isoInt(({Uint8List img, int w, int h, String fn, int p}) args) {
  final raw = _callInt(args.img, args.w, args.h, args.fn, args.p);
  return _encodePng(raw, args.w, args.h);
}

Uint8List _isoCanny(({Uint8List img, int w, int h, int t1, int t2}) args) {
  final lib  = _openLib();
  final call = lib.lookupFunction<_CannyNative, _CannyDart>('apply_canny');
  final free = lib.lookupFunction<_FreeNative, _FreeDart>('free_result');
  final inPtr = malloc.allocate<Uint8>(args.img.length);
  inPtr.asTypedList(args.img.length).setAll(0, args.img);
  final szPtr = malloc.allocate<Int32>(1);
  final result = call(inPtr, args.w, args.h, args.t1, args.t2, szPtr);
  final sz = szPtr.value;
  malloc.free(inPtr); malloc.free(szPtr);
  if (result == nullptr || sz <= 0) throw Exception('apply_canny returned null');
  final out = Uint8List.fromList(result.asTypedList(sz));
  free(result);
  return _encodePng(out, args.w, args.h);
}

Uint8List _isoRotate(({Uint8List img, int w, int h, double angle}) args) {
  final lib  = _openLib();
  final call = lib.lookupFunction<_RotateNative, _RotateDart>('apply_rotate');
  final free = lib.lookupFunction<_FreeNative, _FreeDart>('free_result');
  final inPtr = malloc.allocate<Uint8>(args.img.length);
  inPtr.asTypedList(args.img.length).setAll(0, args.img);
  final owPtr = malloc.allocate<Int32>(1);
  final ohPtr = malloc.allocate<Int32>(1);
  final szPtr = malloc.allocate<Int32>(1);
  final result = call(inPtr, args.w, args.h, args.angle, owPtr, ohPtr, szPtr);
  final ow = owPtr.value, oh = ohPtr.value, sz = szPtr.value;
  malloc.free(inPtr); malloc.free(owPtr); malloc.free(ohPtr); malloc.free(szPtr);
  if (result == nullptr || sz <= 0) throw Exception('apply_rotate returned null');
  final out = Uint8List.fromList(result.asTypedList(sz));
  free(result);
  return _encodePng(out, ow, oh);
}

// ─── Public API ──────────────────────────────────────────────────────────────

class NativeProcessor {
  /// Decode inputBytes once and return (rgba, w, h).
  static ({Uint8List rgba, int width, int height}) decodeImage(Uint8List bytes) =>
      _decode(bytes);

  static Future<Uint8List> _simple(Uint8List bytes, String fn) async {
    final d = _decode(bytes);
    return Isolate.run(() => _isoSimple((img: d.rgba, w: d.width, h: d.height, fn: fn)));
  }

  static Future<Uint8List> _floatOp(Uint8List bytes, String fn, double p) async {
    final d = _decode(bytes);
    return Isolate.run(() => _isoFloat((img: d.rgba, w: d.width, h: d.height, fn: fn, p: p)));
  }

  static Future<Uint8List> _intOp(Uint8List bytes, String fn, int p) async {
    final d = _decode(bytes);
    return Isolate.run(() => _isoInt((img: d.rgba, w: d.width, h: d.height, fn: fn, p: p)));
  }

  // ── Artistic filters ──────────────────────────────────────────────────────
  static Future<Uint8List> applyGrayscale(Uint8List b)    => _simple(b, 'apply_grayscale');
  static Future<Uint8List> applySepia(Uint8List b)        => _simple(b, 'apply_sepia');
  static Future<Uint8List> applyVintage(Uint8List b)      => _simple(b, 'apply_vintage');
  static Future<Uint8List> applyEmboss(Uint8List b)       => _simple(b, 'apply_emboss');
  static Future<Uint8List> applyPencilSketch(Uint8List b) => _simple(b, 'apply_pencil_sketch');
  static Future<Uint8List> applyColorSketch(Uint8List b)  => _simple(b, 'apply_color_sketch');
  static Future<Uint8List> applyCartoon(Uint8List b)      => _simple(b, 'apply_cartoon');
  static Future<Uint8List> applyGhibli(Uint8List b)       => _simple(b, 'apply_ghibli');

  // ── Adjustments ───────────────────────────────────────────────────────────
  /// value: -100 to +100
  static Future<Uint8List> adjustBrightness(Uint8List b, double v) =>
      _floatOp(b, 'adjust_brightness', v);
  static Future<Uint8List> adjustContrast(Uint8List b, double v) =>
      _floatOp(b, 'adjust_contrast', v);
  /// value: 0.0 to 2.0
  static Future<Uint8List> adjustSaturation(Uint8List b, double v) =>
      _floatOp(b, 'adjust_saturation', v);
  /// strength: 0.0 to 3.0
  static Future<Uint8List> applySharpen(Uint8List b, double strength) =>
      _floatOp(b, 'apply_sharpen', strength);
  static Future<Uint8List> enhanceDetails(Uint8List b) =>
      _simple(b, 'enhance_details');
  /// gamma: 0.5 to 2.0
  static Future<Uint8List> applyGamma(Uint8List b, double gamma) =>
      _floatOp(b, 'apply_gamma', gamma);

  // ── Blurs ─────────────────────────────────────────────────────────────────
  /// kernelSize: 3, 5, 7, ...
  static Future<Uint8List> applyGaussianBlur(Uint8List b, int k) =>
      _intOp(b, 'apply_gaussian_blur', k);
  static Future<Uint8List> applyMedianBlur(Uint8List b, int k) =>
      _intOp(b, 'apply_median_blur', k);
  static Future<Uint8List> applyBilateral(Uint8List b) =>
      _simple(b, 'apply_bilateral');

  // ── Edge detection ────────────────────────────────────────────────────────
  static Future<Uint8List> applySobel(Uint8List b) =>
      _simple(b, 'apply_sobel');
  static Future<Uint8List> applyCanny(Uint8List b, {int t1 = 50, int t2 = 150}) async {
    final d = _decode(b);
    return Isolate.run(() => _isoCanny((img: d.rgba, w: d.width, h: d.height, t1: t1, t2: t2)));
  }

  // ── Transforms ────────────────────────────────────────────────────────────
  static Future<Uint8List> applyRotate(Uint8List b, double angleDeg) async {
    final d = _decode(b);
    return Isolate.run(() => _isoRotate((img: d.rgba, w: d.width, h: d.height, angle: angleDeg)));
  }
  /// direction: 'horizontal' or 'vertical'
  static Future<Uint8List> applyFlip(Uint8List b, String direction) =>
      _intOp(b, 'apply_flip', direction == 'horizontal' ? 0 : 1);
}
