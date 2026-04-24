import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

enum CropAspectPreset { free, square, ratio4x3, ratio16x9 }

class CropWrapper extends StatefulWidget {
  final Uint8List imageBytes;

  const CropWrapper({super.key, required this.imageBytes});

  @override
  State<CropWrapper> createState() => _CropWrapperState();
}

class _CropWrapperState extends State<CropWrapper> {
  final CropController _controller = CropController();
  CropAspectPreset _preset = CropAspectPreset.free;

  bool _isCropping = false;

  double? get _aspectRatio {
    switch (_preset) {
      case CropAspectPreset.square:
        return 1.0;
      case CropAspectPreset.ratio4x3:
        return 4 / 3;
      case CropAspectPreset.ratio16x9:
        return 16 / 9;
      case CropAspectPreset.free:
        return null;
    }
  }

  Future<void> _onCropped(Uint8List croppedBytes) async {
    setState(() => _isCropping = false);
    if (!mounted) return;
    Navigator.of(context).pop(croppedBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crop'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isCropping
                ? null
                : () => Navigator.of(context).pop<Uint8List?>(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isCropping
                ? null
                : () {
                    setState(() => _isCropping = true);
                    _controller.crop();
                  },
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _presetButton('Free', CropAspectPreset.free),
                _presetButton('1:1', CropAspectPreset.square),
                _presetButton('4:3', CropAspectPreset.ratio4x3),
                _presetButton('16:9', CropAspectPreset.ratio16x9),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _controller,
              onCropped: _onCropped,
              withCircleUi: false,
              fixCropRect: false,
              aspectRatio: _aspectRatio,
              baseColor: Colors.black,
              maskColor: Colors.black54,
              radius: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetButton(String text, CropAspectPreset preset) {
    final isSelected = _preset == preset;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(text),
        selected: isSelected,
        onSelected: (_) => setState(() => _preset = preset),
      ),
    );
  }
}
