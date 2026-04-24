import 'dart:typed_data';

class FilterItem {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Future<Uint8List> Function(Uint8List) apply;

  const FilterItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.apply,
  });
}
