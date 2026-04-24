import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../models/edit_history.dart';
import '../services/ml_service.dart';
import '../services/native_processor.dart';
import '../services/storage_service.dart';

class EditorProvider extends ChangeNotifier {
  final MLService    _ml      = MLService();
  final EditHistory  _history = EditHistory();
  final ImagePicker  _picker  = ImagePicker();

  // ── Image state ────────────────────────────────────────────────────────────
  Uint8List? currentBytes;
  Uint8List? preEnhanceBytes;
  Uint8List? postEnhanceBytes;

  // ── UI state ───────────────────────────────────────────────────────────────
  bool   isLoading       = false;
  bool   isEnhancing     = false;
  bool   showBeforeAfter = false;
  String loadingMessage  = '';
  double enhStrength     = 1.0;

  // ── Adjustment state ───────────────────────────────────────────────────────
  double brightness = 0.0;
  double contrast   = 0.0;
  double saturation = 1.0;
  double sharpen    = 0.0;
  double gamma      = 1.0;

  // ── Crop state ─────────────────────────────────────────────────────────────
  bool isCropping = false;

  // ── Computed ───────────────────────────────────────────────────────────────
  bool get canUndo  => _history.canUndo;
  bool get canRedo  => _history.canRedo;
  bool get hasImage => currentBytes != null;
  bool get mlLoaded => _ml.isLoaded;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _ml.loadModel();
    notifyListeners();
  }

  // ── Pick from gallery ──────────────────────────────────────────────────────
  Future<void> pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      _loadBytes(bytes);
    } catch (e) {
      debugPrint('[Editor] Pick error: $e');
    }
  }

  // ── Capture from camera ────────────────────────────────────────────────────
  Future<void> captureImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      _loadBytes(bytes);
    } catch (e) {
      debugPrint('[Editor] Camera error: $e');
    }
  }

  void _loadBytes(Uint8List bytes) {
    currentBytes   = bytes;
    _history.clear();
    _history.push(bytes);
    _resetAdjustments();
    showBeforeAfter  = false;
    preEnhanceBytes  = null;
    postEnhanceBytes = null;
    notifyListeners();
  }

  void _resetAdjustments() {
    brightness = 0.0;
    contrast   = 0.0;
    saturation = 1.0;
    sharpen    = 0.0;
    gamma      = 1.0;
  }

  // ── History ────────────────────────────────────────────────────────────────
  void undo() {
    final prev = _history.undo();
    if (prev != null) {
      currentBytes = prev;
      notifyListeners();
    }
  }

  void redo() {
    final next = _history.redo();
    if (next != null) {
      currentBytes = next;
      notifyListeners();
    }
  }

  void resetToOriginal() {
    final orig = _history.original;
    if (orig != null) {
      currentBytes    = orig;
      showBeforeAfter = false;
      preEnhanceBytes = null;
      postEnhanceBytes = null;
      _resetAdjustments();
      notifyListeners();
    }
  }

  // ── Generic operation runner ───────────────────────────────────────────────
  Future<void> _runOp(
    String message,
    Future<Uint8List> Function(Uint8List) op,
  ) async {
    if (currentBytes == null || isLoading) return;
    isLoading     = true;
    loadingMessage = message;
    notifyListeners();
    try {
      final result = await op(currentBytes!);
      currentBytes = result;
      _history.push(result);
    } catch (e) {
      debugPrint('[Editor] Op error: $e');
    } finally {
      isLoading     = false;
      loadingMessage = '';
      notifyListeners();
    }
  }

  // ── Adjustments ────────────────────────────────────────────────────────────

  Future<void> applyBrightness(double value) async {
    brightness = value;
    await _runOp('Adjusting brightness...',
        (b) => NativeProcessor.adjustBrightness(b, value));
  }

  Future<void> applyContrast(double value) async {
    contrast = value;
    await _runOp('Adjusting contrast...',
        (b) => NativeProcessor.adjustContrast(b, value));
  }

  Future<void> applySaturation(double value) async {
    saturation = value;
    await _runOp('Adjusting vibrance...',
        (b) => NativeProcessor.adjustSaturation(b, value));
  }

  Future<void> applySharpen(double value) async {
    sharpen = value;
    await _runOp('Sharpening...', (b) => NativeProcessor.applySharpen(b, value));
  }

  Future<void> applyGamma(double value) async {
    gamma = value;
    await _runOp('Adjusting exposure...',
        (b) => NativeProcessor.applyGamma(b, value));
  }

  Future<void> applySmartEnhance() async =>
      _runOp('Enhancing details...', NativeProcessor.enhanceDetails);

  // ── Filters ────────────────────────────────────────────────────────────────

  Future<void> applyPencilArt() async =>
      _runOp('Creating pencil art...', NativeProcessor.applyPencilSketch);

  Future<void> applyAnimeStyle() async =>
      _runOp('Applying anime style...', NativeProcessor.applyGhibli);

  Future<void> applyColorPop() async =>
      _runOp('Applying color pop...', NativeProcessor.applyColorSketch);

  Future<void> applyComicBook() async =>
      _runOp('Applying comic book style...', NativeProcessor.applyCartoon);

  Future<void> apply3DRelief() async =>
      _runOp('Applying 3D relief...', NativeProcessor.applyEmboss);

  Future<void> applyWarmClassic() async =>
      _runOp('Applying warm classic...', NativeProcessor.applySepia);

  Future<void> applyRetroFilm() async =>
      _runOp('Applying retro film...', NativeProcessor.applyVintage);

  Future<void> applyBlackAndWhite() async =>
      _runOp('Converting to B&W...', NativeProcessor.applyGrayscale);

  // ── Retouch ────────────────────────────────────────────────────────────────

  Future<void> applySoftFocus(int size) async =>
      _runOp('Applying soft focus...',
          (b) => NativeProcessor.applyGaussianBlur(b, size));

  Future<void> applySmoothSkin() async =>
      _runOp('Smoothing skin...', NativeProcessor.applyBilateral);

  Future<void> applyNoiseClean(int size) async =>
      _runOp('Cleaning noise...',
          (b) => NativeProcessor.applyMedianBlur(b, size));

  Future<void> applyEdgeArt() async =>
      _runOp('Creating edge art...', NativeProcessor.applySobel);

  Future<void> applySketchEdges() async =>
      _runOp('Creating sketch edges...', NativeProcessor.applyCanny);

  // ── Transforms ─────────────────────────────────────────────────────────────

  Future<void> rotateRight() async =>
      _runOp('Rotating...', (b) => NativeProcessor.applyRotate(b, 90.0));

  Future<void> rotateLeft() async =>
      _runOp('Rotating...', (b) => NativeProcessor.applyRotate(b, -90.0));

  Future<void> flipHorizontal() async =>
      _runOp('Flipping...', (b) => NativeProcessor.applyFlip(b, 'horizontal'));

  Future<void> flipVertical() async =>
      _runOp('Flipping...', (b) => NativeProcessor.applyFlip(b, 'vertical'));

  // ── AI Enhancement ─────────────────────────────────────────────────────────

  Future<void> runAIEnhance() async {
    if (currentBytes == null || isEnhancing) return;
    isEnhancing   = true;
    loadingMessage = 'AI is enhancing your photo...';
    notifyListeners();
    try {
      preEnhanceBytes = Uint8List.fromList(currentBytes!);
      final enhanced  = await _ml.enhance(currentBytes!);
      postEnhanceBytes = enhanced;
      currentBytes    = enhanced;
      showBeforeAfter = true;
      _history.push(enhanced);
    } catch (e) {
      debugPrint('[Editor] AI enhance error: $e');
    } finally {
      isEnhancing   = false;
      loadingMessage = '';
      notifyListeners();
    }
  }

  Future<void> updateEnhanceStrength(double s) async {
    if (preEnhanceBytes == null || postEnhanceBytes == null) return;
    enhStrength = s;
    notifyListeners();
    final blended = await _ml.blend(preEnhanceBytes!, postEnhanceBytes!, s);
    currentBytes  = blended;
    notifyListeners();
  }

  void acceptEnhancement() {
    showBeforeAfter = false;
    preEnhanceBytes = null;
    notifyListeners();
  }

  void discardEnhancement() {
    if (preEnhanceBytes != null) {
      currentBytes = preEnhanceBytes;
      _history.undo();
    }
    showBeforeAfter  = false;
    preEnhanceBytes  = null;
    postEnhanceBytes = null;
    notifyListeners();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<String?> saveImage() async {
    if (currentBytes == null) return null;
    isLoading     = true;
    loadingMessage = 'Saving to gallery...';
    notifyListeners();
    try {
      return await StorageService.saveToGallery(currentBytes!);
    } finally {
      isLoading     = false;
      loadingMessage = '';
      notifyListeners();
    }
  }

  // ── Crop ───────────────────────────────────────────────────────────────────

  void startCrop() {
    isCropping = true;
    notifyListeners();
  }

  void applyCrop(Uint8List croppedBytes) {
    currentBytes = croppedBytes;
    _history.push(croppedBytes);
    isCropping = false;
    notifyListeners();
  }

  void cancelCrop() {
    isCropping = false;
    notifyListeners();
  }

  // ── Public loadBytes (for preloaded image from HomeScreen) ────────────────
  void loadBytes(Uint8List bytes) => _loadBytes(bytes);

  // ── Generate a small thumbnail for filter preview ──────────────────────────
  Future<Uint8List> generateFilterThumb(String filterId, Uint8List src) async {
    // Downscale source to 100x100 first for speed
    final small = await compute(_resizeToThumb, src);
    switch (filterId) {
      case 'pencilArt':   return NativeProcessor.applyPencilSketch(small);
      case 'animeStyle':  return NativeProcessor.applyGhibli(small);
      case 'colorPop':    return NativeProcessor.applyColorSketch(small);
      case 'comicBook':   return NativeProcessor.applyCartoon(small);
      case '3dRelief':    return NativeProcessor.applyEmboss(small);
      case 'warmClassic': return NativeProcessor.applySepia(small);
      case 'retroFilm':   return NativeProcessor.applyVintage(small);
      case 'blackWhite':  return NativeProcessor.applyGrayscale(small);
      default:            return small;
    }
  }

  // ── Apply filter by string ID ──────────────────────────────────────────────
  Future<void> applyFilterById(String id) async {
    switch (id) {
      case 'original':    resetToOriginal(); return;
      case 'pencilArt':   return applyPencilArt();
      case 'animeStyle':  return applyAnimeStyle();
      case 'colorPop':    return applyColorPop();
      case 'comicBook':   return applyComicBook();
      case '3dRelief':    return apply3DRelief();
      case 'warmClassic': return applyWarmClassic();
      case 'retroFilm':   return applyRetroFilm();
      case 'blackWhite':  return applyBlackAndWhite();
    }
  }

  @override
  void dispose() {
    _ml.dispose();
    super.dispose();
  }
}

// Top-level isolate for thumbnail resize
Uint8List _resizeToThumb(Uint8List bytes) {
  final img_lib = img.decodeImage(bytes);
  if (img_lib == null) return bytes;
  final thumb = img.copyResize(img_lib, width: 100, height: 100,
      interpolation: img.Interpolation.average);
  return Uint8List.fromList(img.encodePng(thumb));
}
