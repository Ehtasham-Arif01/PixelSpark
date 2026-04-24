import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/image_data.dart';
import '../services/native_processor.dart';

class _FilterDef {
  final String name;
  final String description;
  final IconData icon;
  final Future<Uint8List> Function(Uint8List) apply;
  const _FilterDef({
    required this.name,
    required this.description,
    required this.icon,
    required this.apply,
  });
}

final _filters = [
  _FilterDef(
    name: 'Pencil Sketch',
    description: 'Convert to grayscale pencil drawing',
    icon: Icons.edit_outlined,
    apply: NativeProcessor.applyPencilSketch,
  ),
  _FilterDef(
    name: 'Ghibli',
    description: 'Soft, dreamy Studio Ghibli style',
    icon: Icons.cloud_outlined,
    apply: NativeProcessor.applyGhibli,
  ),
  _FilterDef(
    name: 'Color Sketch',
    description: 'Colored pencil drawing effect',
    icon: Icons.color_lens_outlined,
    apply: NativeProcessor.applyColorSketch,
  ),
  _FilterDef(
    name: 'Cartoon',
    description: 'Flat color cartoon / comic style',
    icon: Icons.face_retouching_natural,
    apply: NativeProcessor.applyCartoon,
  ),
  _FilterDef(
    name: 'Emboss',
    description: '3D embossed relief effect',
    icon: Icons.texture,
    apply: NativeProcessor.applyEmboss,
  ),
  _FilterDef(
    name: 'Sepia',
    description: 'Classic vintage sepia tone',
    icon: Icons.photo_filter_outlined,
    apply: NativeProcessor.applySepia,
  ),
  _FilterDef(
    name: 'Vintage',
    description: 'Retro vignette + warm tones',
    icon: Icons.camera_outlined,
    apply: NativeProcessor.applyVintage,
  ),
  _FilterDef(
    name: 'Grayscale',
    description: 'Black and white conversion',
    icon: Icons.contrast,
    apply: NativeProcessor.applyGrayscale,
  ),
];

class FiltersScreen extends StatefulWidget {
  final ImageData imageData;
  const FiltersScreen({super.key, required this.imageData});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late ImageData _data;
  int? _processingIndex;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _data = widget.imageData;
  }

  Future<void> _apply(int index) async {
    setState(() { _processingIndex = index; _errorMsg = null; });
    try {
      final result = await _filters[index].apply(_data.currentBytes);
      setState(() {
        _data = _data.withEdit(result);
        _processingIndex = null;
      });
    } catch (e) {
      setState(() {
        _processingIndex = null;
        _errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1A2E),
        foregroundColor: Colors.white,
        title: const Text('Artistic Filters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _data),
            child: const Text('Done',
                style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview
          Container(
            height: 260,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.memory(_data.currentBytes, fit: BoxFit.contain),
                if (_processingIndex != null)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: Color(0xFF0EA5E9)),
                          const SizedBox(height: 10),
                          Text(
                            'Applying ${_filters[_processingIndex!].name}…',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_errorMsg != null)
            Container(
              color: Colors.red.shade900,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                      child: Text(_errorMsg!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12))),
                  GestureDetector(
                    onTap: () => setState(() => _errorMsg = null),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          // Filter grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.4,
              ),
              itemCount: _filters.length,
              itemBuilder: (context, i) {
                final f = _filters[i];
                final isLoading = _processingIndex == i;
                return _FilterCard(
                  name: f.name,
                  description: f.description,
                  icon: f.icon,
                  isLoading: isLoading,
                  onTap: _processingIndex != null ? null : () => _apply(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;
  const _FilterCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF132236),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF0EA5E9)),
                      )
                    : Icon(icon, color: const Color(0xFF0EA5E9), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 2),
                    Text(description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.45),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
