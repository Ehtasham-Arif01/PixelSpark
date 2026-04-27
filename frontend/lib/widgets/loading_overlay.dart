import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

import 'dart:ui';

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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
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
                        size: 52,
                      ),
                    )
                  else
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.navy),
                        strokeWidth: 4,
                      ),
                    ),
  
                  const SizedBox(height: 24),
  
                  // Label
                  if (widget.isAI)
                    Shimmer.fromColors(
                      baseColor: AppTheme.navy,
                      highlightColor: AppTheme.cyan,
                      child: const Text(
                        'AI Enhancing...',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppTheme.navy,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Text(
                      widget.message,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
  
                  const SizedBox(height: 20),
  
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isAI ? AppTheme.aiPurple : AppTheme.navy,
                      ),
                      minHeight: 6,
                    ),
                  ),
  
                  const SizedBox(height: 12),
  
                  Text(
                    'Please wait while we process',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
