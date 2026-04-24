import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/editor_provider.dart';
import '../theme/app_theme.dart';

Future<void> showSaveDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _SaveDialog(),
  );
}

class _SaveDialog extends StatefulWidget {
  const _SaveDialog();

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EditorProvider>();
    final bytes    = provider.currentBytes;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Save Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Preview
            if (bytes != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    bytes,
                    width: 160,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Text(
              'Where would you like to save?',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),

            const SizedBox(height: 12),

            // Save to gallery
            _OptionTile(
              icon: Icons.photo_library_rounded,
              iconColor: AppTheme.navy,
              title: 'Save to Gallery',
              subtitle: 'Add to your device photos',
              isLoading: _saving,
              onTap: () async {
                setState(() => _saving = true);
                final path = await provider.saveImage();
                if (!mounted) return;
                Navigator.of(context).pop();
                _showResult(context, path);
              },
            ),

            const SizedBox(height: 8),

            // Share — save then show snackbar (share plugin not in deps, so graceful)
            _OptionTile(
              icon: Icons.share_rounded,
              iconColor: AppTheme.cyanDark,
              title: 'Share',
              subtitle: 'Share with other apps',
              isLoading: false,
              onTap: () async {
                // Save first, then inform user
                final path = await provider.saveImage();
                if (!mounted) return;
                Navigator.of(context).pop();
                if (path != null) {
                  _showSnack(context,
                      '✓ Saved! Open from Gallery to share.',
                      isSuccess: true);
                } else {
                  _showSnack(context,
                      'Save failed. Check permissions.',
                      isSuccess: false);
                }
              },
            ),

            const SizedBox(height: 8),

            // Cancel
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResult(BuildContext context, String? path) {
    if (path != null) {
      _showSnack(context, '✓ Saved to Gallery', isSuccess: true);
    } else {
      _showSnack(context, 'Save failed. Check permissions.',
          isSuccess: false);
    }
  }

  void _showSnack(BuildContext context, String msg,
      {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  iconColor)),
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppTheme.textGrey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}
