import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// ── Top-level thumbnail isolate ───────────────────────────────────────────────

Uint8List _thumbIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final thumb = img.copyResize(decoded, width: 120, height: 120,
      interpolation: img.Interpolation.average);
  return Uint8List.fromList(img.encodePng(thumb));
}

// ── StorageService ────────────────────────────────────────────────────────────

class StorageService {
  /// Save bytes to device gallery and app private directory.
  /// Returns saved file path or null on failure.
  static Future<String?> saveToGallery(
    Uint8List bytes, {
    String? name,
  }) async {
    try {
      // Request permissions
      final status = await _requestPermission();
      if (!status) {
        debugPrint('[Storage] Permission denied');
        return null;
      }

      final filename = name ??
          'PixelSpark_${DateTime.now().millisecondsSinceEpoch}.png';

      // Save to device gallery
      final result = await ImageGallerySaver.saveImage(
        bytes,
        name: filename,
        isReturnImagePathOfIOS: false,
      );
      debugPrint('[Storage] Gallery save result: $result');

      // Save a copy to app private directory
      final dir  = await _getDir();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('[Storage] Private copy saved: ${file.path}');

      return file.path;
    } catch (e) {
      debugPrint('[Storage] Save error: $e');
      return null;
    }
  }

  /// Load all saved PNG images from app private directory, newest first.
  static Future<List<File>> getSavedImages() async {
    try {
      final dir  = await _getDir();
      final all  = dir.listSync().whereType<File>().where(
            (f) => f.path.toLowerCase().endsWith('.png'),
          ).toList();
      all.sort((a, b) =>
          b.statSync().modified.compareTo(a.statSync().modified));
      return all;
    } catch (e) {
      debugPrint('[Storage] List error: $e');
      return [];
    }
  }

  /// Generate a 120×120 thumbnail.
  static Future<Uint8List> thumbnail(Uint8List bytes) async {
    return compute(_thumbIsolate, bytes);
  }

  /// Delete a saved image. Returns true on success.
  static Future<bool> deleteImage(String path) async {
    try {
      await File(path).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final sdk = await _androidSdkVersion();
      if (sdk >= 33) {
        final s = await Permission.photos.request();
        return s.isGranted || s.isLimited;
      } else {
        final s = await Permission.storage.request();
        return s.isGranted;
      }
    }
    return true;
  }

  static Future<int> _androidSdkVersion() async {
    try {
      // Reads android.os.Build.VERSION.SDK_INT via process info
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 30;
    } catch (_) {
      return 30;
    }
  }

  static Future<Directory> _getDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir  = Directory('${base.path}/PixelSpark');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
