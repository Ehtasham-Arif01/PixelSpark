import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/tool_item.dart';
import '../providers/editor_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/save_dialog.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  List<File> _recentFiles = [];
  Map<String, Uint8List> _thumbCache = {};

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final files = await StorageService.getSavedImages();
    if (!mounted) return;
    setState(() => _recentFiles = files.take(10).toList());
    _generateThumbs();
  }

  Future<void> _generateThumbs() async {
    for (final f in _recentFiles) {
      if (_thumbCache.containsKey(f.path)) continue;
      try {
        final bytes = await f.readAsBytes();
        final thumb = await StorageService.thumbnail(bytes);
        if (!mounted) return;
        setState(() => _thumbCache[f.path] = thumb);
      } catch (_) {}
    }
  }

  void _openEditor({String? tool, Uint8List? imageBytes}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            EditorScreen(initialTool: tool, preloadedBytes: imageBytes),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: AppConstants.normalAnim,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(provider)),
          SliverToBoxAdapter(child: _buildAICard(provider)),
          SliverToBoxAdapter(child: _buildToolGrid()),
          if (_recentFiles.isNotEmpty)
            SliverToBoxAdapter(child: _buildRecentSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────

  Widget _buildHero(EditorProvider provider) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                // Logo
                Row(children: [
                  const Icon(Icons.auto_awesome,
                      color: AppTheme.cyan, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'PixelSpark',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.cyan,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PRO',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                ]),
                const Spacer(),
                if (_recentFiles.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.photo_library,
                        color: Colors.white70),
                    onPressed: () => setState(() => _navIndex = 3),
                    tooltip: 'Gallery',
                  ),
              ],
            ),

            const Spacer(),

            // Centre content
            const Icon(Icons.auto_awesome,
                color: AppTheme.cyan, size: 40),
            const SizedBox(height: 10),
            const Text(
              'Transform Your Photos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI-powered editing, entirely on your device',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _HeroButton(
                    label: '📷  From Gallery',
                    filled: true,
                    onTap: () async {
                      await provider.pickImage();
                      if (provider.hasImage && mounted) {
                        _openEditor(imageBytes: provider.currentBytes);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroButton(
                    label: '📸  Camera',
                    filled: false,
                    onTap: () async {
                      await provider.captureImage();
                      if (provider.hasImage && mounted) {
                        _openEditor(imageBytes: provider.currentBytes);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── AI Card ───────────────────────────────────────────────────────────────

  Widget _buildAICard(EditorProvider provider) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('✦ ',
                      style: TextStyle(color: AppTheme.aiPurple, fontSize: 16)),
                  const Text(
                    'AI Auto Enhance',
                    style: TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  provider.mlLoaded
                      ? 'MIRNet model ready • Intelligent photo enhancement'
                      : 'C++ engine ready • Pick a photo to start',
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    if (!provider.hasImage) await provider.pickImage();
                    if (provider.hasImage && mounted) {
                      _openEditor(tool: 'ai');
                    }
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.aiGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Enhance Now →',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.aiGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_fix_high,
                color: Colors.white, size: 40),
          ),
        ],
      ),
      ),
    );
  }

  // ── Tool grid ─────────────────────────────────────────────────────────────

  Widget _buildToolGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Tools',
                  style: TextStyle(
                      color: AppTheme.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () => _openEditor(),
                child: const Text('See all →',
                    style: TextStyle(
                        color: AppTheme.textGrey, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: kHomeTools.length,
            itemBuilder: (_, i) => _ToolCard(
              tool: kHomeTools[i],
              onTap: () => _openEditor(tool: kHomeTools[i].route),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent section ────────────────────────────────────────────────────────

  Widget _buildRecentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Edits',
                  style: TextStyle(
                      color: AppTheme.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: _loadRecent,
                child: const Text('Refresh',
                    style: TextStyle(
                        color: AppTheme.textGrey, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final f    = _recentFiles[i];
                final thumb = _thumbCache[f.path];
                return GestureDetector(
                  onTap: () async {
                    final bytes = await f.readAsBytes();
                    if (mounted) {
                      _openEditor(imageBytes: bytes);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: thumb != null
                        ? Image.memory(thumb,
                            width: 120, height: 120,
                            fit: BoxFit.cover)
                        : Container(
                            width: 120,
                            height: 120,
                            color: AppTheme.border,
                            child: const Icon(
                                Icons.image_outlined,
                                color: AppTheme.textGrey),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const items = [
      BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded), label: 'Home'),
      BottomNavigationBarItem(
          icon: Icon(Icons.auto_fix_high), label: 'Enhance'),
      BottomNavigationBarItem(
          icon: Icon(Icons.edit_rounded), label: 'Editor'),
      BottomNavigationBarItem(
          icon: Icon(Icons.photo_library_rounded), label: 'Gallery'),
      BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded), label: 'Settings'),
    ];

    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) {
        setState(() => _navIndex = i);
        if (i == 1) {
          context.read<EditorProvider>().pickImage().then((_) {
            final p = context.read<EditorProvider>();
            if (p.hasImage && mounted) _openEditor(tool: 'ai');
          });
        } else if (i == 2) {
          _openEditor();
        }
      },
      items: items,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.navy,
      unselectedItemColor: AppTheme.textGrey,
      backgroundColor: AppTheme.white,
      elevation: 12,
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _HeroButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _HeroButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: filled ? AppTheme.navy : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final ToolItem tool;
  final VoidCallback onTap;

  const _ToolCard({required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tool.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tool.label,
                      style: const TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(tool.subtitle,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
