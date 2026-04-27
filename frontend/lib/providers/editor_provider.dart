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
  String? lastError;

  // ── Adjustment state ───────────────────────────────────────────────────────
  double _brightness = 0.0;
  double _contrast   = 0.0;
  double _saturation = 1.0;
  double _sharpen    = 0.0;
  double _gamma      = 1.0;

  double get brightness => _brightness;
  set brightness(double v) { _brightness = v; notifyListeners(); }

  double get contrast => _contrast;
  set contrast(double v) { _contrast = v; notifyListeners(); }

  double get saturation => _saturation;
  set saturation(double v) { _saturation = v; notifyListeners(); }

  double get sharpen => _sharpen;
  set sharpen(double v) { _sharpen = v; notifyListeners(); }

  double get gamma => _gamma;
  set gamma(double v) { _gamma = v; notifyListeners(); }

  // ── Crop state ─────────────────────────────────────────────────────────────
  bool isCropping = false;

  // ── Filter thumbnails ──────────────────────────────────────────────────────
  Map<String, Uint8List> filterThumbnails = {};

  // ── Unsaved changes ────────────────────────────────────────────────────────
  bool get hasUnsavedChanges => _history.historyCount > 1;

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
    filterThumbnails = {};
    _generateFilterThumbnails(bytes);
    notifyListeners();
  }

  void _resetAdjustments() {
    brightness = 0.0;
    contrast   = 0.0;
    saturation = 1.0;
    sharpen    = 0.0;
    gamma      = 1.0;
  }

  // ── Debounce ───────────────────────────────────────────────────────────────
  Timer? _debounceTimer;
  void _debouncedApply(double value, Future<void> Function(double) fn) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 350),
      () => fn(value),
    );
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
  Future<void> _runOp(String msg, Future<Uint8List> Function(Uint8List) op) async {
    if (!hasImage) return;
    isLoading = true;
    loadingMessage = msg;
    lastError = null;
    notifyListeners();

    try {
      final res = await op(currentBytes!);
      currentBytes = res;
      _history.push(res);
    } catch (e) {
      debugPrint('[Editor] Op error: $e');
      lastError = 'Operation failed: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Adjustments ────────────────────────────────────────────────────────────

  Future<void> applyBrightness(double value) async {
    _debouncedApply(value, (v) async {
      brightness = v;
      await _runOp('Adjusting brightness...',
          (b) => NativeProcessor.adjustBrightness(b, v));
    });
  }

  Future<void> applyContrast(double value) async {
    _debouncedApply(value, (v) async {
      contrast = v;
      await _runOp('Adjusting contrast...',
          (b) => NativeProcessor.adjustContrast(b, v));
    });
  }

  Future<void> applySaturation(double value) async {
    _debouncedApply(value, (v) async {
      saturation = v;
      await _runOp('Adjusting vibrance...',
          (b) => NativeProcessor.adjustSaturation(b, v));
    });
  }

  Future<void> applySharpen(double value) async {
    _debouncedApply(value, (v) async {
      sharpen = v;
      await _runOp('Sharpening...', (b) => NativeProcessor.applySharpen(b, v));
    });
  }

  Future<void> applyGamma(double value) async {
    _debouncedApply(value, (v) async {
      gamma = v;
      await _runOp('Adjusting exposure...',
          (b) => NativeProcessor.applyGamma(b, v));
    });
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
      lastError = 'AI Enhancement failed: ${e.toString()}';
    } finally {
      isEnhancing = false;
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

  Future<void> _generateFilterThumbnails(Uint8List bytes) async {
    try {
      // Step 1: Generate 100x100 base thumbnail
      final thumb = await compute(_resizeIsolate, _ResizePayload(bytes: bytes, size: 100));
      
      // Step 2: Apply each filter to thumbnail in parallel
      final ids = [
        'pencilArt', 'animeStyle', 'colorPop', 'comicBook',
        '3dRelief', 'warmClassic', 'retroFilm', 'blackWhite'
      ];
      
      final futures = ids.map((id) => compute(_applyFilterIsolate, _FilterPayload(thumb, id))).toList();
      final results = await Future.wait(futures);
      
      // Step 3: Store in map
      filterThumbnails = {'original': thumb};
      for (int i = 0; i < ids.length; i++) {
        filterThumbnails[ids[i]] = results[i];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[Editor] Thumbnail generation error: $e');
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

// ── Isolate Payloads ────────────────────────────────────────────────────────

class _ResizePayload {
  final Uint8List bytes;
  final int size;
  _ResizePayload({required this.bytes, required this.size});
}

class _FilterPayload {
  final Uint8List bytes;
  final String filterId;
  _FilterPayload(this.bytes, this.filterId);
}

// ── Top-level isolates for pure Dart processing ──────────────────────────────

Uint8List _resizeIsolate(_ResizePayload p) {
  final image = img.decodeImage(p.bytes);
  if (image == null) return p.bytes;
  final thumb = img.copyResize(image, width: p.size, height: p.size,
      interpolation: img.Interpolation.average);
  return Uint8List.fromList(img.encodePng(thumb));
}

Uint8List _applyFilterIsolate(_FilterPayload p) {
  final image = img.decodeImage(p.bytes);
  if (image == null) return p.bytes;

  switch (p.filterId) {
    case 'blackWhite':
    case 'grayscale':
      img.grayscale(image);
      break;
    case 'warmClassic':
      // Sepia approximation
      img.sepia(image);
      break;
    case 'retroFilm':
      img.sepia(image, amount: 0.5);
      img.vignette(image);
      break;
    case 'pencilArt':
      img.grayscale(image);
      img.sobel(image);
      img.invert(image);
      break;
    case '3dRelief':
      img.emboss(image);
      break;
    case 'animeStyle':
      // Simplified: boost saturation and brightness
      img.adjustColor(image, saturation: 1.5, brightness: 1.2);
      break;
    case 'colorPop':
      img.adjustColor(image, saturation: 2.0);
      break;
    case 'comicBook':
      img.quantize(image, numberOfColors: 8);
      break;
  }

  return Uint8List.fromList(img.encodePng(image));
}
