import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

class FilterThumbnail extends StatelessWidget {
  final String name;
  final Uint8List? thumbnail;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const FilterThumbnail({
    super.key,
    required this.name,
    required this.onTap,
    this.thumbnail,
    this.isSelected = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              // Thumbnail image or shimmer placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppTheme.cyan, width: 2.5)
                        : Border.all(color: Colors.transparent, width: 2.5),
                  ),
                  child: thumbnail != null && !isLoading
                      ? Image.memory(
                          thumbnail!,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        )
                      : Shimmer.fromColors(
                          baseColor: AppTheme.border,
                          highlightColor: Colors.white,
                          child: Container(
                            width: 80,
                            height: 80,
                            color: AppTheme.border,
                          ),
                        ),
                ),
              ),

              // Selected overlay: checkmark
              if (isSelected)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cyan.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: AppTheme.cyan,
                        size: 28,
                      ),
                    ),
                  ),
                ),

              // Loading spinner overlay
              if (isLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppTheme.navy : AppTheme.textGrey,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
