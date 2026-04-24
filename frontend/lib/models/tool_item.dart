import 'package:flutter/material.dart';

class ToolItem {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const ToolItem({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

const List<ToolItem> kHomeTools = [
  ToolItem(
    id: 'adjust',
    label: 'Light & Color',
    subtitle: 'Brightness, contrast, vibrance',
    icon: Icons.tune,
    color: Color(0xFF1E3A5F),
    route: 'adjust',
  ),
  ToolItem(
    id: 'filters',
    label: 'Style Filters',
    subtitle: 'Artistic photo styles',
    icon: Icons.filter,
    color: Color(0xFF0097A7),
    route: 'filters',
  ),
  ToolItem(
    id: 'retouch',
    label: 'Retouch',
    subtitle: 'Smooth, soften, sharpen',
    icon: Icons.face_retouching_natural,
    color: Color(0xFF7C3AED),
    route: 'retouch',
  ),
  ToolItem(
    id: 'transform',
    label: 'Crop & Rotate',
    subtitle: 'Reshape your photo',
    icon: Icons.crop_rotate,
    color: Color(0xFF00897B),
    route: 'transform',
  ),
];
