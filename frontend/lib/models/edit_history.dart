import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';

class EditHistory {
  final List<Uint8List> _stack = [];
  int _index = -1;

  void push(Uint8List bytes) {
    // Remove any redo states beyond current index
    if (_index < _stack.length - 1) {
      _stack.removeRange(_index + 1, _stack.length);
    }
    
    // Compress to JPEG 85% for history storage to save RAM
    final compressed = _compressForHistory(bytes);
    _stack.add(compressed);
    
    if (_stack.length > AppConstants.maxHistory) {
      _stack.removeAt(0);
    }
    _index = _stack.length - 1;
  }

  Uint8List _compressForHistory(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    // History stores compressed versions to save RAM
    return Uint8List.fromList(
      img.encodeJpg(image, quality: 85)
    );
  }

  Uint8List? undo() {
    if (_index <= 0) return null;
    _index--;
    return _stack[_index];
  }

  Uint8List? redo() {
    if (_index >= _stack.length - 1) return null;
    _index++;
    return _stack[_index];
  }

  Uint8List? get current =>
      _stack.isEmpty ? null : _stack[_index];

  bool get canUndo => _index > 0;
  bool get canRedo => _index < _stack.length - 1;

  int get historyCount => _stack.length;
  int get currentIndex => _index;

  void clear() {
    _stack.clear();
    _index = -1;
  }

  Uint8List? get original =>
      _stack.isEmpty ? null : _stack[0];
}
