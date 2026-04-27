import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/editor_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/adjustment_slider.dart';
import '../widgets/before_after_slider.dart';
import '../widgets/filter_thumbnail.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/save_dialog.dart';

class EditorScreen extends StatefulWidget {
  final String? initialTool;
  final Uint8List? preloadedBytes;
  const EditorScreen({super.key, this.initialTool, this.preloadedBytes});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _cropCtrl = CropController();
  final _transformCtrl = TransformationController();
  String? _selectedFilter;
  String? _loadingFilter;

  static const _tabs = ['✦ AI', 'Light', 'Style', 'Retouch', 'Tools'];

  static const _filters = [
    {'id': 'original',     'name': 'Original'},
    {'id': 'pencilArt',    'name': 'Pencil Art'},
    {'id': 'animeStyle',   'name': 'Anime Style'},
    {'id': 'colorPop',     'name': 'Color Pop'},
    {'id': 'comicBook',    'name': 'Comic Book'},
    {'id': '3dRelief',     'name': '3D Relief'},
    {'id': 'warmClassic',  'name': 'Warm Classic'},
    {'id': 'retroFilm',    'name': 'Retro Film'},
    {'id': 'blackWhite',   'name': 'Black & White'},
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTool == 'ai')        initialIndex = 0;
    else if (widget.initialTool == 'adjust') initialIndex = 1;
    else if (widget.initialTool == 'filters') initialIndex = 2;
    else if (widget.initialTool == 'retouch') initialIndex = 3;
    else if (widget.initialTool == 'transform') initialIndex = 4;
    _tabCtrl = TabController(length: _tabs.length, vsync: this, initialIndex: initialIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<EditorProvider>();
      if (widget.preloadedBytes != null && !p.hasImage) {
        // Load preloaded bytes into provider via internal method
        p.loadBytes(widget.preloadedBytes!);
      }
      context.read<EditorProvider>().addListener(_errorListener);
    });
  }

  void _errorListener() {
    final error = context.read<EditorProvider>().lastError;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    context.read<EditorProvider>().removeListener(_errorListener);
    _tabCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
  }

  Future<void> _applyFilter(String id, EditorProvider p) async {
    if (_selectedFilter == id) return;
    setState(() { _selectedFilter = id; _loadingFilter = id; });
    try {
      await p.applyFilterById(id);
    } finally {
      if (mounted) setState(() => _loadingFilter = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final p = context.read<EditorProvider>();
        if (!p.hasUnsavedChanges) {
          Navigator.pop(context);
          return;
        }
        
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved edits. Are you sure you want to exit?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard', style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        );
        
        if (discard == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildCanvas()),
              _buildBottomPanel(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Spacer(),
          Selector<EditorProvider, bool>(
            selector: (_, p) => p.canUndo,
            builder: (ctx, canUndo, _) => IconButton(
              icon: Icon(Icons.undo,
                  color: canUndo ? Colors.white : Colors.white30),
              onPressed: canUndo ? ctx.read<EditorProvider>().undo : null,
              tooltip: 'Undo',
            ),
          ),
          Selector<EditorProvider, bool>(
            selector: (_, p) => p.canRedo,
            builder: (ctx, canRedo, _) => IconButton(
              icon: Icon(Icons.redo,
                  color: canRedo ? Colors.white : Colors.white30),
              onPressed: canRedo ? ctx.read<EditorProvider>().redo : null,
              tooltip: 'Redo',
            ),
          ),
          Selector<EditorProvider, bool>(
            selector: (_, p) => p.hasImage,
            builder: (ctx, hasImage, _) => IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: hasImage ? () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset changes?'),
                    content: const Text('All edits will be discarded. This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Reset', style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  context.read<EditorProvider>().resetToOriginal();
                }
              } : null,
              tooltip: 'Reset',
            ),
          ),
          const SizedBox(width: 4),
          Selector<EditorProvider, bool>(
            selector: (_, p) => p.hasImage,
            builder: (ctx, hasImage, _) => GestureDetector(
              onTap: hasImage ? () => showSaveDialog(context) : null,
              child: Opacity(
                opacity: hasImage ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.saveGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Image canvas ──────────────────────────────────────────────────────────
  Widget _buildCanvas() {
    return Selector<EditorProvider, bool>(
      selector: (_, p) => p.hasImage,
      builder: (ctx, hasImage, _) {
        if (!hasImage) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt, color: Colors.white30, size: 64),
                const SizedBox(height: 16),
                const Text('No photo selected',
                    style: TextStyle(color: Colors.white60, fontSize: 16)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ctx.read<EditorProvider>().pickImage(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Choose Photo'),
                ),
              ],
            ),
          );
        }

        return Selector<EditorProvider, bool>(
          selector: (_, p) => p.isCropping,
          builder: (ctx, isCropping, _) {
            if (isCropping) {
              return Stack(children: [
                Crop(
                  controller: _cropCtrl,
                  image: ctx.read<EditorProvider>().currentBytes!,
                  onCropped: (Uint8List result) {
                    ctx.read<EditorProvider>().applyCrop(result);
                  },
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: ctx.read<EditorProvider>().cancelCrop,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _cropCtrl.crop(),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navy),
                        child: const Text('Apply Crop'),
                      ),
                    ],
                  ),
                ),
              ]);
            }

            return LayoutBuilder(
              builder: (ctx, constraints) {
                return Stack(
                  children: [
                    GestureDetector(
                      onDoubleTap: _resetZoom,
                      child: InteractiveViewer(
                        transformationController: _transformCtrl,
                        minScale: 0.5,
                        maxScale: 5.0,
                        child: Center(
                          child: Selector<EditorProvider, ({bool show, Uint8List? before, Uint8List? after})>(
                            selector: (_, p) => (
                              show: p.showBeforeAfter,
                              before: p.preEnhanceBytes,
                              after: p.currentBytes
                            ),
                            builder: (ctx, data, _) {
                              if (data.show && data.before != null && data.after != null) {
                                return BeforeAfterSlider(
                                  beforeBytes: data.before!,
                                  afterBytes: data.after!,
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                );
                              }
                              return RepaintBoundary(
                                child: data.after != null
                                    ? Image.memory(data.after!,
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true)
                                    : const SizedBox.shrink(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Selector<EditorProvider, ({bool loading, bool enhancing, String msg})>(
                      selector: (_, p) => (
                        loading: p.isLoading,
                        enhancing: p.isEnhancing,
                        msg: p.loadingMessage
                      ),
                      builder: (ctx, data, _) {
                        if (data.loading || data.enhancing) {
                          return LoadingOverlay(
                              message: data.msg,
                              isAI: data.enhancing);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Bottom panel ──────────────────────────────────────────────────────────
  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Tab bar
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            labelColor: AppTheme.navy,
            unselectedLabelColor: AppTheme.textGrey,
            indicatorColor: AppTheme.cyan,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          // Tab content
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildAITab(),
                _buildLightTab(),
                _buildStyleTab(),
                _buildRetouchTab(),
                _buildToolsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: AI ─────────────────────────────────────────────────────────────
  Widget _buildAITab() {
    return Selector<EditorProvider, ({bool enhancing, bool hasImg, bool showBA, double strength, bool mlLoaded})>(
      selector: (_, p) => (
        enhancing: p.isEnhancing,
        hasImg: p.hasImage,
        showBA: p.showBeforeAfter,
        strength: p.enhStrength,
        mlLoaded: p.mlLoaded
      ),
      builder: (ctx, data, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhance button
            GestureDetector(
              onTap: data.enhancing || !data.hasImg ? null : ctx.read<EditorProvider>().runAIEnhance,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.aiGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: data.enhancing
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white))
                      : const Text('✦  Smart Enhance',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                ),
              ),
            ),
  
            const SizedBox(height: 16),
  
            // Before/after controls
            if (data.showBA) ...[
              Text('Enhancement Strength',
                  style: TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 6),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.aiPurple,
                  inactiveTrackColor: AppTheme.border,
                  thumbColor: AppTheme.aiPurple,
                  trackHeight: 3,
                ),
                child: Slider(
                  value: data.strength,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) => ctx.read<EditorProvider>().updateEnhanceStrength(v),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: ctx.read<EditorProvider>().discardEnhancement,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          minimumSize: const Size(0, 48)),
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: ctx.read<EditorProvider>().acceptEnhancement,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.aiPurple,
                          minimumSize: const Size(0, 48)),
                      child: const Text('✓ Accept'),
                    ),
                  ),
                ],
              ),
            ],
  
            const SizedBox(height: 12),
  
            // Model status
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        data.mlLoaded ? AppTheme.success : AppTheme.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data.mlLoaded
                      ? 'AI Engine — Ready'
                      : 'Optimization Engine — Active',
                  style: TextStyle(
                      color: AppTheme.textGrey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Light & Color ──────────────────────────────────────────────────
  Widget _buildLightTab() {
    return Selector<EditorProvider, ({double b, double c, double s, double sh, double g, bool hasImg})>(
      selector: (_, p) => (
        b: p.brightness,
        c: p.contrast,
        s: p.saturation,
        sh: p.sharpen,
        g: p.gamma,
        hasImg: p.hasImage
      ),
      builder: (ctx, data, _) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            AdjustmentSlider(
              icon: Icons.wb_sunny_outlined,
              label: 'Brightness',
              value: data.b,
              min: AppConstants.brightnessMin,
              max: AppConstants.brightnessMax,
              defaultValue: AppConstants.brightnessDefault,
              onChanged: ctx.read<EditorProvider>().applyBrightness,
            ),
            const SizedBox(height: 8),
            AdjustmentSlider(
              icon: Icons.contrast,
              label: 'Contrast',
              value: data.c,
              min: AppConstants.contrastMin,
              max: AppConstants.contrastMax,
              defaultValue: AppConstants.contrastDefault,
              onChanged: ctx.read<EditorProvider>().applyContrast,
            ),
            const SizedBox(height: 8),
            AdjustmentSlider(
              icon: Icons.palette_outlined,
              label: 'Vibrance',
              value: data.s,
              min: AppConstants.saturationMin,
              max: AppConstants.saturationMax,
              defaultValue: AppConstants.saturationDefault,
              onChanged: ctx.read<EditorProvider>().applySaturation,
            ),
            const SizedBox(height: 8),
            AdjustmentSlider(
              icon: Icons.details,
              label: 'Sharpness',
              value: data.sh,
              min: AppConstants.sharpenMin,
              max: AppConstants.sharpenMax,
              defaultValue: AppConstants.sharpenDefault,
              onChanged: ctx.read<EditorProvider>().applySharpen,
            ),
            const SizedBox(height: 8),
            AdjustmentSlider(
              icon: Icons.radio_button_unchecked,
              label: 'Exposure',
              value: data.g,
              min: AppConstants.gammaMin,
              max: AppConstants.gammaMax,
              defaultValue: AppConstants.gammaDefault,
              onChanged: ctx.read<EditorProvider>().applyGamma,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: data.hasImg ? ctx.read<EditorProvider>().applySmartEnhance : null,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Smart Enhance'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.navy,
                    side: const BorderSide(color: AppTheme.navy),
                    minimumSize: const Size(0, 52)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 3: Style Filters ──────────────────────────────────────────────────
  Widget _buildStyleTab() {
    return Selector<EditorProvider, ({Map<String, Uint8List> thumbs, bool hasImg})>(
      selector: (_, p) => (thumbs: p.filterThumbnails, hasImg: p.hasImage),
      builder: (ctx, data, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          itemCount: _filters.length,
          itemBuilder: (_, i) {
            final f  = _filters[i];
            final id = f['id']!;
            return FilterThumbnail(
              name: f['name']!,
              thumbnail: data.thumbs[id],
              isSelected: _selectedFilter == id,
              isLoading: _loadingFilter == id,
              onTap: data.hasImg ? () => _applyFilter(id, ctx.read<EditorProvider>()) : () {},
            );
          },
        ),
      ),
    );
  }

  // ── Tab 4: Retouch ────────────────────────────────────────────────────────
  Widget _buildRetouchTab() {
    return Selector<EditorProvider, bool>(
      selector: (_, p) => p.hasImage,
      builder: (ctx, hasImg, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _RetouchCard(
              title: 'Soft Focus',
              subtitle: 'Gentle blur for dreamy effect',
              icon: Icons.blur_on,
              child: _SliderApplyRow(
                min: 1, max: 15, initial: 5,
                onApply: (v) => ctx.read<EditorProvider>().applySoftFocus(v.toInt()),
              ),
            ),
            const SizedBox(height: 8),
            _RetouchCard(
              title: 'Smooth Skin',
              subtitle: 'Edge-preserving skin smoothing',
              icon: Icons.face_retouching_natural,
              child: _ApplyButton(label: 'Apply', onTap: hasImg ? ctx.read<EditorProvider>().applySmoothSkin : null),
            ),
            const SizedBox(height: 8),
            _RetouchCard(
              title: 'Noise Clean',
              subtitle: 'Remove grain and noise',
              icon: Icons.grain,
              child: _SliderApplyRow(
                min: 1, max: 7, initial: 3,
                onApply: (v) => ctx.read<EditorProvider>().applyNoiseClean(v.toInt()),
              ),
            ),
            const SizedBox(height: 8),
            _RetouchCard(
              title: 'Edge Art',
              subtitle: 'Artistic edge detection',
              icon: Icons.tonality,
              child: _ApplyButton(label: 'Apply', onTap: hasImg ? ctx.read<EditorProvider>().applyEdgeArt : null),
            ),
            const SizedBox(height: 8),
            _RetouchCard(
              title: 'Sketch Style',
              subtitle: 'Stylized sketch effect',
              icon: Icons.draw_outlined,
              child: _ApplyButton(label: 'Apply', onTap: hasImg ? ctx.read<EditorProvider>().applySketchEdges : null),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 5: Transform ──────────────────────────────────────────────────────
  Widget _buildToolsTab() {
    return Selector<EditorProvider, bool>(
      selector: (_, p) => p.hasImage,
      builder: (ctx, hasImg, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rotate & Flip',
                style: TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                _TransformBtn(
                    icon: Icons.rotate_right, label: 'Rotate R',
                    onTap: hasImg ? ctx.read<EditorProvider>().rotateRight : null),
                const SizedBox(width: 8),
                _TransformBtn(
                    icon: Icons.rotate_left, label: 'Rotate L',
                    onTap: hasImg ? ctx.read<EditorProvider>().rotateLeft : null),
                const SizedBox(width: 8),
                _TransformBtn(
                    icon: Icons.flip, label: 'Flip H',
                    onTap: hasImg ? ctx.read<EditorProvider>().flipHorizontal : null),
                const SizedBox(width: 8),
                _TransformBtn(
                    icon: Icons.flip, label: 'Flip V',
                    onTap: hasImg ? ctx.read<EditorProvider>().flipVertical : null),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Crop',
                style: TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasImg ? ctx.read<EditorProvider>().startCrop : null,
                icon: const Icon(Icons.crop),
                label: const Text('✂  Start Crop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _RetouchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _RetouchCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.navy, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final String label;
  final Future<void> Function()? onTap;

  const _ApplyButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SliderApplyRow extends StatefulWidget {
  final double min;
  final double max;
  final double initial;
  final void Function(double) onApply;

  const _SliderApplyRow({
    required this.min,
    required this.max,
    required this.initial,
    required this.onApply,
  });

  @override
  State<_SliderApplyRow> createState() => _SliderApplyRowState();
}

class _SliderApplyRowState extends State<_SliderApplyRow> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: (widget.max - widget.min).toInt(),
            activeColor: AppTheme.cyan,
            inactiveColor: AppTheme.border,
            onChanged: (v) => setState(() => _value = v),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => widget.onApply(_value),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.navy,
            foregroundColor: Colors.white,
            minimumSize: const Size(70, 36),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Apply', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _TransformBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _TransformBtn(
      {required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.navy, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
