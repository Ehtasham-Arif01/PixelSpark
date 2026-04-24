import 'dart:io';

import 'package:image/image.dart';

void main() {
  const int size = 1024;
  final img = Image(width: size, height: size);

  // Background (Navy)
  fill(img, color: ColorRgb8(30, 58, 95)); // #1E3A5F

  // Inner white square
  final int padding = 200;
  final int innerSize = size - (padding * 2);
  fillRect(
    img,
    x1: padding,
    y1: padding,
    x2: size - padding,
    y2: size - padding,
    color: ColorRgb8(255, 255, 255),
    radius: 180, // Rounded corners
  );

  // Draw 'P'
  fillRect(
    img,
    x1: 300,
    y1: 300,
    x2: 380,
    y2: 724,
    color: ColorRgb8(30, 58, 95),
  );
  fillRect(
    img,
    x1: 300,
    y1: 300,
    x2: 520,
    y2: 520,
    color: ColorRgb8(30, 58, 95),
    radius: 80,
  );
  fillRect(
    img,
    x1: 380,
    y1: 380,
    x2: 440,
    y2: 440,
    color: ColorRgb8(255, 255, 255),
    radius: 20,
  );

  // Draw 'S'
  fillRect(
    img,
    x1: 580,
    y1: 300,
    x2: 724,
    y2: 724,
    color: ColorRgb8(30, 58, 95),
    radius: 80,
  );
  fillRect(
    img,
    x1: 660,
    y1: 380,
    x2: 724,
    y2: 460,
    color: ColorRgb8(255, 255, 255),
    radius: 40,
  );
  fillRect(
    img,
    x1: 580,
    y1: 540,
    x2: 644,
    y2: 644,
    color: ColorRgb8(255, 255, 255),
    radius: 40,
  );

  // Decorative dots (Cyan)
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      fillCircle(
        img,
        x: 460 + (i * 40),
        y: 800 + (j * 40),
        radius: 10,
        color: ColorRgb8(0, 188, 212), // #00BCD4
      );
    }
  }

  final dir = Directory('assets/icon');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final file = File('assets/icon/app_icon.png');
  file.writeAsBytesSync(encodePng(img));
  print('Icon generated at: \${file.path}');
}
