import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum ToolButtonStyle { primary, secondary, ghost, danger }

class ToolButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final ToolButtonStyle style;
  final bool isLoading;
  final bool isSelected;
  final Color? color;

  const ToolButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.style = ToolButtonStyle.primary,
    this.isLoading = false,
    this.isSelected = false,
    this.color,
  });

  @override
  State<ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<ToolButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _scaleCtrl.reverse();
  void _onTapUp(_)   => _scaleCtrl.forward();
  void _onTapCancel() => _scaleCtrl.forward();

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppTheme.navy;

    BoxDecoration decoration;
    TextStyle labelStyle;
    Color iconColor;

    switch (widget.style) {
      case ToolButtonStyle.primary:
        decoration = BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
        labelStyle = const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14);
        iconColor = Colors.white;
        break;

      case ToolButtonStyle.secondary:
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: effectiveColor, width: 1.5),
        );
        labelStyle = TextStyle(
            color: effectiveColor, fontWeight: FontWeight.w600, fontSize: 14);
        iconColor = effectiveColor;
        break;

      case ToolButtonStyle.ghost:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        );
        labelStyle = TextStyle(
            color: effectiveColor, fontWeight: FontWeight.w500, fontSize: 14);
        iconColor = effectiveColor;
        break;

      case ToolButtonStyle.danger:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.error, width: 1.5),
        );
        labelStyle = const TextStyle(
            color: AppTheme.error, fontWeight: FontWeight.w600, fontSize: 14);
        iconColor = AppTheme.error;
        break;
    }

    // Selected override: cyan border + checkmark overlay
    if (widget.isSelected) {
      decoration = decoration.copyWith(
        border: Border.all(color: AppTheme.cyan, width: 2.5),
      );
    }

    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: 52,
          decoration: decoration,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  ),
                )
              else ...[
                Icon(widget.icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(widget.label, style: labelStyle),
              if (widget.isSelected) ...[
                const Spacer(),
                Icon(Icons.check_circle, color: AppTheme.cyan, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
