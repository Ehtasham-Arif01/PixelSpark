import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AdjustmentSlider extends StatefulWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final double defaultValue;
  final ValueChanged<double> onChanged;
  final String unit;

  const AdjustmentSlider({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.onChanged,
    this.unit = '',
  });

  @override
  State<AdjustmentSlider> createState() => _AdjustmentSliderState();
}

class _AdjustmentSliderState extends State<AdjustmentSlider> {
  Timer? _debounce;
  late double _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(AdjustmentSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _localValue = widget.value;
    }
  }

  void _handleChange(double val) {
    setState(() => _localValue = val);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(val);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = (_localValue - widget.defaultValue).abs() > 0.001;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: AppTheme.navy, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            // Value pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.navy,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_localValue.toStringAsFixed(1)}${widget.unit}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            if (isDirty)
              GestureDetector(
                onTap: () => _handleChange(widget.defaultValue),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.refresh,
                      color: AppTheme.textGrey, size: 18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.cyan,
            inactiveTrackColor: AppTheme.border,
            thumbColor: AppTheme.navy,
            overlayColor: AppTheme.navy.withOpacity(0.12),
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: _localValue.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            onChanged: _handleChange,
          ),
        ),
      ],
    );
  }
}
