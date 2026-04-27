import 'dart:typed_data';

import 'package:flutter/material.dart';

class BeforeAfterSlider extends StatefulWidget {
  final Uint8List beforeBytes;
  final Uint8List afterBytes;
  final double width;
  final double height;

  const BeforeAfterSlider({
    super.key,
    required this.beforeBytes,
    required this.afterBytes,
    required this.width,
    required this.height,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _position = 0.5;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanUpdate: (details) {
        setState(() {
          _position = (_position + details.delta.dx / widget.width)
              .clamp(0.01, 0.99);
        });
      },
      onPanEnd: (_) => setState(() => _isDragging = false),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            // AFTER image (full width background)
            Positioned.fill(
              child: Image.memory(
                widget.afterBytes,
                fit: BoxFit.contain,
              ),
            ),

            // BEFORE image clipped to left of divider
            Positioned.fill(
              child: ClipRect(
                clipper: _SideClipper(_position, widget.width),
                child: Image.memory(
                  widget.beforeBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Divider line
            Positioned(
              left: widget.width * _position - 1,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: Colors.white70),
            ),

            // Drag handle
            Positioned(
              left: widget.width * _position - 22,
              top: widget.height / 2 - 22,
              child: AnimatedScale(
                scale: _isDragging ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.compare_arrows,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
              ),
            ),

            // BEFORE label
            Positioned(
              bottom: 12,
              left: 12,
              child: _SliderLabel('BEFORE'),
            ),

            // AFTER label
            Positioned(
              bottom: 12,
              right: 12,
              child: _SliderLabel('AFTER'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideClipper extends CustomClipper<Rect> {
  final double fraction;
  final double width;

  _SideClipper(this.fraction, this.width);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_SideClipper old) => old.fraction != fraction;
}

class _SliderLabel extends StatelessWidget {
  final String text;
  const _SliderLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
