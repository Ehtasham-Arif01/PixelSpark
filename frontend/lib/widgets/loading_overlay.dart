import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

class LoadingOverlay extends StatefulWidget {
  final String message;
  final bool isAI;

  const LoadingOverlay({
    super.key,
    required this.message,
    this.isAI = false,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotateCtrl;
  late final Animation<double>   _rotation;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _rotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotateCtrl);
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon / spinner
                if (widget.isAI)
                  AnimatedBuilder(
                    animation: _rotation,
                    builder: (_, child) => Transform.rotate(
                      angle: _rotation.value,
                      child: child,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.aiPurple,
                      size: 48,
                    ),
                  )
                else
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.navy),
                    strokeWidth: 3,
                  ),

                const SizedBox(height: 20),

                // Label
                if (widget.isAI)
                  Shimmer.fromColors(
                    baseColor: AppTheme.navy,
                    highlightColor: AppTheme.cyan,
                    child: Text(
                      'AI Enhancing...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.navy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Text(
                    widget.message,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: AppTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isAI ? AppTheme.aiPurple : AppTheme.navy,
                    ),
                    minHeight: 4,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Please wait',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
