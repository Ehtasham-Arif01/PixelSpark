import 'dart:typed_data';

class ImageData {
  final Uint8List originalBytes;   // original, never mutated
  final Uint8List currentBytes;    // currently displayed (PNG)
  final List<Uint8List> history;   // undo stack
  final String? sourcePath;

  const ImageData({
    required this.originalBytes,
    required this.currentBytes,
    this.history = const [],
    this.sourcePath,
  });

  ImageData copyWith({Uint8List? currentBytes, List<Uint8List>? history}) =>
      ImageData(
        originalBytes: originalBytes,
        currentBytes: currentBytes ?? this.currentBytes,
        history: history ?? this.history,
        sourcePath: sourcePath,
      );

  ImageData withEdit(Uint8List newBytes) => copyWith(
    currentBytes: newBytes,
    history: [...history, currentBytes],
  );

  ImageData undo() {
    if (history.isEmpty) return this;
    return copyWith(
      currentBytes: history.last,
      history: history.sublist(0, history.length - 1),
    );
  }

  bool get canUndo => history.isNotEmpty;
}
