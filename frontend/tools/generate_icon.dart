// Run with: dart run tools/generate_icon.dart
// Generates: assets/icon/app_icon.png (1024x1024)
// Then run:  flutter pub run flutter_launcher_icons

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() async {
  const size = 1024;
  final canvas = img.Image(width: size, height: size);

  // ── Background: deep navy gradient ──────────────
  // Simulate radial gradient: dark center → slightly lighter edge
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = (x - size / 2) / (size / 2);
      final dy = (y - size / 2) / (size / 2);
      final dist = sqrt(dx * dx + dy * dy).clamp(0.0, 1.0);

      // Navy: #1E3A5F → darker #0D2137
      final r = (30  + (13  - 30)  * dist).round().clamp(0, 255);
      final g = (58  + (33  - 58)  * dist).round().clamp(0, 255);
      final b = (95  + (55  - 95)  * dist).round().clamp(0, 255);

      canvas.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // ── Rounded rectangle background ────────────────
  // Draw white rounded square (subtle, for depth)
  _drawRoundedRect(canvas,
    x: 120, y: 120, w: 784, h: 784,
    radius: 160,
    r: 255, g: 255, b: 255, a: 20,  // very subtle white
  );

  // ── Lightning bolt "spark" shape ─────────────────
  // PixelSpark = pixel grid + spark/lightning
  // Draw stylized "PS" monogram with spark accent

  // Main shape: Abstract "P" + lightning bolt merged
  // Left vertical bar of P:
  _drawRect(canvas,
    x: 290, y: 280, w: 80, h: 420,
    r: 0, g: 188, b: 212, a: 255,   // cyan #00BCD4
  );

  // Top curve of P (horizontal bars):
  _drawRect(canvas,
    x: 290, y: 280, w: 260, h: 75,
    r: 0, g: 188, b: 212, a: 255,
  );
  _drawRect(canvas,
    x: 290, y: 460, w: 220, h: 75,
    r: 0, g: 188, b: 212, a: 255,
  );

  // Right curve of P (vertical):
  _drawRect(canvas,
    x: 490, y: 355, w: 75, h: 180,
    r: 0, g: 188, b: 212, a: 255,
  );

  // Lightning bolt "S" / spark on right side:
  // Top of bolt:
  _drawParallelogram(canvas,
    x1: 570, y1: 280, x2: 750, y2: 280,
    x3: 680, y3: 510, x4: 570, y4: 510,
    r: 255, g: 255, b: 255, a: 255,  // white
  );
  // Bottom of bolt:
  _drawParallelogram(canvas,
    x1: 580, y1: 530, x2: 700, y2: 530,
    x3: 750, y3: 720, x4: 570, y4: 720,
    r: 0, g: 188, b: 212, a: 255,   // cyan
  );

  // ── Pixel grid dots (bottom-right) ───────────────
  // 4x4 grid of small dots — "pixel" concept
  for (int row = 0; row < 3; row++) {
    for (int col = 0; col < 3; col++) {
      final cx = 700 + col * 42;
      final cy = 760 + row * 42;
      _drawCircle(canvas, cx, cy, 12,
        r: 255, g: 255, b: 255, a: (row == 0 && col == 0) ? 255 : 120,
      );
    }
  }

  // ── Sparkle accents ──────────────────────────────
  // 4-point star sparkles in corners of the icon
  _drawSparkle(canvas, cx: 820, cy: 200, size: 35,
    r: 255, g: 255, b: 255, a: 200);
  _drawSparkle(canvas, cx: 200, cy: 820, size: 25,
    r: 0, g: 188, b: 212, a: 180);
  _drawSparkle(canvas, cx: 870, cy: 780, size: 20,
    r: 255, g: 255, b: 255, a: 150);

  // ── Subtle vignette ──────────────────────────────
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = (x - size / 2) / (size / 2);
      final dy = (y - size / 2) / (size / 2);
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > 0.85) {
        final alpha = ((dist - 0.85) / 0.3 * 120).round().clamp(0, 120);
        final px = canvas.getPixel(x, y);
        final nr = ((px.r * (255 - alpha)) ~/ 255).clamp(0, 255);
        final ng = ((px.g * (255 - alpha)) ~/ 255).clamp(0, 255);
        final nb = ((px.b * (255 - alpha)) ~/ 255).clamp(0, 255);
        canvas.setPixelRgba(x, y, nr, ng, nb, 255);
      }
    }
  }

  // ── Save ─────────────────────────────────────────
  final dir = Directory('assets/icon');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final pngBytes = img.encodePng(canvas);
  File('assets/icon/app_icon.png').writeAsBytesSync(pngBytes);

  print('✓ Icon generated: assets/icon/app_icon.png');
  print('  Size: ${pngBytes.length ~/ 1024}KB');
  print('  Next: flutter pub run flutter_launcher_icons');
}

// ── Drawing helpers ────────────────────────────────

void _drawRect(img.Image canvas, {
  required int x, required int y,
  required int w, required int h,
  required int r, required int g,
  required int b, required int a,
}) {
  for (int py = y; py < y + h && py < canvas.height; py++) {
    for (int px = x; px < x + w && px < canvas.width; px++) {
      if (px >= 0 && py >= 0) {
        _blendPixel(canvas, px, py, r, g, b, a);
      }
    }
  }
}

void _drawRoundedRect(img.Image canvas, {
  required int x, required int y,
  required int w, required int h,
  required int radius,
  required int r, required int g,
  required int b, required int a,
}) {
  for (int py = y; py < y + h; py++) {
    for (int px = x; px < x + w; px++) {
      if (_inRoundedRect(px, py, x, y, w, h, radius)) {
        _blendPixel(canvas, px, py, r, g, b, a);
      }
    }
  }
}

bool _inRoundedRect(int px, int py,
    int x, int y, int w, int h, int r) {
  if (px < x || px >= x+w || py < y || py >= y+h) return false;
  // Corner checks
  final corners = [
    [x+r, y+r], [x+w-r, y+r],
    [x+r, y+h-r], [x+w-r, y+h-r],
  ];
  for (final c in corners) {
    final dx = px - c[0]; final dy = py - c[1];
    if (dx < 0 && dy < 0 && dx*dx + dy*dy > r*r) {
      return false;
    }
    if (dx > 0 && dy < 0 && dx*dx + dy*dy > r*r) {
      return false;
    }
    if (dx < 0 && dy > 0 && dx*dx + dy*dy > r*r) {
      return false;
    }
    if (dx > 0 && dy > 0 && dx*dx + dy*dy > r*r) {
      return false;
    }
  }
  return true;
}

void _drawCircle(img.Image canvas, int cx, int cy, int radius,
    {required int r, required int g,
     required int b, required int a}) {
  for (int py = cy - radius; py <= cy + radius; py++) {
    for (int px = cx - radius; px <= cx + radius; px++) {
      final dx = px - cx; final dy = py - cy;
      if (dx*dx + dy*dy <= radius*radius) {
        if (px>=0 && py>=0 && px<canvas.width && py<canvas.height)
          _blendPixel(canvas, px, py, r, g, b, a);
      }
    }
  }
}

void _drawParallelogram(img.Image canvas, {
  required int x1, required int y1,
  required int x2, required int y2,
  required int x3, required int y3,
  required int x4, required int y4,
  required int r, required int g,
  required int b, required int a,
}) {
  final minY = [y1,y2,y3,y4].reduce(min);
  final maxY = [y1,y2,y3,y4].reduce(max);
  for (int py = minY; py <= maxY; py++) {
    final t = (py - minY) / (maxY - minY + 1);
    final lx = (x1 + (x4 - x1) * t).round();
    final rx = (x2 + (x3 - x2) * t).round();
    for (int px = lx; px <= rx; px++) {
      if (px>=0 && py>=0 && px<canvas.width && py<canvas.height)
        _blendPixel(canvas, px, py, r, g, b, a);
    }
  }
}

void _drawSparkle(img.Image canvas, {
  required int cx, required int cy,
  required int size,
  required int r, required int g,
  required int b, required int a,
}) {
  // 4-point star: horizontal + vertical + diagonal bars
  _drawRect(canvas,
    x: cx - size, y: cy - size~/4,
    w: size*2, h: size~/2,
    r: r, g: g, b: b, a: a,
  );
  _drawRect(canvas,
    x: cx - size~/4, y: cy - size,
    w: size~/2, h: size*2,
    r: r, g: g, b: b, a: a,
  );
}

void _blendPixel(img.Image canvas, int x, int y,
    int r, int g, int b, int a) {
  if (a == 255) {
    canvas.setPixelRgba(x, y, r, g, b, 255);
    return;
  }
  final existing = canvas.getPixel(x, y);
  final alpha = a / 255.0;
  final nr = (existing.r * (1-alpha) + r * alpha).round();
  final ng = (existing.g * (1-alpha) + g * alpha).round();
  final nb = (existing.b * (1-alpha) + b * alpha).round();
  canvas.setPixelRgba(x, y, nr, ng, nb, 255);
}
