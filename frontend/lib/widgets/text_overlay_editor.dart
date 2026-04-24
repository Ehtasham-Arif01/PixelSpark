import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextOverlayData {
  final String text;
  final String fontFamily;
  final Color color;
  final double fontSize;
  Offset position;

  TextOverlayData({
    required this.text,
    required this.fontFamily,
    required this.color,
    required this.fontSize,
    this.position = Offset.zero,
  });
}

class TextOverlayEditor extends StatefulWidget {
  const TextOverlayEditor({super.key});

  @override
  State<TextOverlayEditor> createState() => _TextOverlayEditorState();
}

class _TextOverlayEditorState extends State<TextOverlayEditor> {
  final TextEditingController _controller = TextEditingController();

  final List<String> _fonts = const [
    'Roboto',
    'Pacifico',
    'Oswald',
    'Dancing Script',
    'Bebas Neue',
  ];

  final List<Color> _colors = const [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.brown,
  ];

  String _selectedFont = 'Roboto';
  Color _selectedColor = Colors.white;
  double _fontSize = 32;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle _fontStyle(String font, {Color? color, double? size}) {
    final appliedColor = color ?? _selectedColor;
    final appliedSize = size ?? _fontSize;
    switch (font) {
      case 'Pacifico':
        return GoogleFonts.pacifico(color: appliedColor, fontSize: appliedSize);
      case 'Oswald':
        return GoogleFonts.oswald(color: appliedColor, fontSize: appliedSize);
      case 'Dancing Script':
        return GoogleFonts.dancingScript(
          color: appliedColor,
          fontSize: appliedSize,
        );
      case 'Bebas Neue':
        return GoogleFonts.bebasNeue(color: appliedColor, fontSize: appliedSize);
      case 'Roboto':
      default:
        return GoogleFonts.roboto(color: appliedColor, fontSize: appliedSize);
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(
      TextOverlayData(
        text: text,
        fontFamily: _selectedFont,
        color: _selectedColor,
        fontSize: _fontSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Text Overlay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type your text',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Font',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _fonts.map((font) {
                    final selected = font == _selectedFont;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(font, style: _fontStyle(font, size: 18)),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedFont = font),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Color',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((color) {
                  final selected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black : Colors.white54,
                          width: selected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                'Font Size',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                min: 12,
                max: 72,
                value: _fontSize,
                divisions: 60,
                label: _fontSize.toStringAsFixed(0),
                onChanged: (value) => setState(() => _fontSize = value),
              ),
              Center(
                child: Text(
                  'Preview',
                  style: _fontStyle(
                    _selectedFont,
                    color: _selectedColor,
                    size: _fontSize.clamp(16, 42),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add Text'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
