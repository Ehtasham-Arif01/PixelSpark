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
  final Map<String, Uint8List?> _filterThumbs = {};
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
      _generateFilterThumbs();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateFilterThumbs() async {
    final p = context.read<EditorProvider>();
    if (!p.hasImage) return;
    final src = p.currentBytes!;
    for (final f in _filters) {
      final id = f['id']!;
      if (id == 'original') {
        setState(() => _filterThumbs[id] = src);
        continue;
      }
      try {
        final thumb = await p.generateFilterThumb(id, src);
        if (mounted) setState(() => _filterThumbs[id] = thumb);
      } catch (_) {}
    }
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
    return Consumer<EditorProvider>(
      builder: (ctx, provider, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(provider),
                Expanded(child: _buildCanvas(provider)),
                _buildBottomPanel(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(EditorProvider p) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.undo,
                color: p.canUndo ? Colors.white : Colors.white30),
            onPressed: p.canUndo ? p.undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: Icon(Icons.redo,
                color: p.canRedo ? Colors.white : Colors.white30),
            onPressed: p.canRedo ? p.redo : null,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: p.hasImage ? p.resetToOriginal : null,
            tooltip: 'Reset',
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: p.hasImage ? () => showSaveDialog(context) : null,
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
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Image canvas ──────────────────────────────────────────────────────────
  Widget _buildCanvas(EditorProvider p) {
    if (!p.hasImage) {
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
              onPressed: () async {
                await p.pickImage();
                if (p.hasImage) _generateFilterThumbs();
              },
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

    if (p.isCropping) {
      return Stack(children: [
        Crop(
          controller: _cropCtrl,
          image: p.currentBytes!,
          onCropped: (Uint8List result) {
            p.applyCrop(result);
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
                onPressed: p.cancelCrop,
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

    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Center(
            child: p.showBeforeAfter &&
                    p.preEnhanceBytes != null
                ? BeforeAfterSlider(
                    beforeBytes: p.preEnhanceBytes!,
                    afterBytes: p.currentBytes!,
                    width: size.width,
                    height: size.height * 0.55,
                  )
                : Image.memory(p.currentBytes!, fit: BoxFit.contain),
          ),
        ),
        if (p.isLoading || p.isEnhancing)
          LoadingOverlay(
              message: p.loadingMessage,
              isAI: p.isEnhancing),
      ],
    );
  }

  // ── Bottom panel ──────────────────────────────────────────────────────────
  Widget _buildBottomPanel(EditorProvider p) {
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
                fontWeight: FontWeight.w700, fontSize: 13),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          // Tab content
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildAITab(p),
                _buildLightTab(p),
                _buildStyleTab(p),
                _buildRetouchTab(p),
                _buildToolsTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: AI ─────────────────────────────────────────────────────────────
  Widget _buildAITab(EditorProvider p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhance button
          GestureDetector(
            onTap: p.isEnhancing || !p.hasImage ? null : p.runAIEnhance,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: p.isEnhancing
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
          if (p.showBeforeAfter) ...[
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
                value: p.enhStrength,
                min: 0.0,
                max: 1.0,
                onChanged: (v) => p.updateEnhanceStrength(v),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: p.discardEnhancement,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error)),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: p.acceptEnhancement,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.aiPurple),
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
                      p.mlLoaded ? AppTheme.success : AppTheme.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                p.mlLoaded
                    ? 'MIRNet AI — Ready'
                    : 'C++ Fallback — Model not found',
                style: TextStyle(
                    color: AppTheme.textGrey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Light & Color ──────────────────────────────────────────────────
  Widget _buildLightTab(EditorProvider p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          AdjustmentSlider(
            icon: Icons.wb_sunny_outlined,
            label: 'Brightness',
            value: p.brightness,
            min: AppConstants.brightnessMin,
            max: AppConstants.brightnessMax,
            defaultValue: AppConstants.brightnessDefault,
            onChanged: p.applyBrightness,
          ),
          const SizedBox(height: 8),
          AdjustmentSlider(
            icon: Icons.contrast,
            label: 'Contrast',
            value: p.contrast,
            min: AppConstants.contrastMin,
            max: AppConstants.contrastMax,
            defaultValue: AppConstants.contrastDefault,
            onChanged: p.applyContrast,
          ),
          const SizedBox(height: 8),
          AdjustmentSlider(
            icon: Icons.palette_outlined,
            label: 'Vibrance',
            value: p.saturation,
            min: AppConstants.saturationMin,
            max: AppConstants.saturationMax,
            defaultValue: AppConstants.saturationDefault,
            onChanged: p.applySaturation,
          ),
          const SizedBox(height: 8),
          AdjustmentSlider(
            icon: Icons.details,
            label: 'Sharpness',
            value: p.sharpen,
            min: AppConstants.sharpenMin,
            max: AppConstants.sharpenMax,
            defaultValue: AppConstants.sharpenDefault,
            onChanged: p.applySharpen,
          ),
          const SizedBox(height: 8),
          AdjustmentSlider(
            icon: Icons.radio_button_unchecked,
            label: 'Exposure',
            value: p.gamma,
            min: AppConstants.gammaMin,
            max: AppConstants.gammaMax,
            defaultValue: AppConstants.gammaDefault,
            onChanged: p.applyGamma,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: p.hasImage ? p.applySmartEnhance : null,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Smart Enhance'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.navy,
                  side: const BorderSide(color: AppTheme.navy)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Style Filters ──────────────────────────────────────────────────
  Widget _buildStyleTab(EditorProvider p) {
    return Padding(
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
            thumbnail: _filterThumbs[id],
            isSelected: _selectedFilter == id,
            isLoading: _loadingFilter == id,
            onTap: p.hasImage ? () => _applyFilter(id, p) : () {},
          );
        },
      ),
    );
  }

  // ── Tab 4: Retouch ────────────────────────────────────────────────────────
  Widget _buildRetouchTab(EditorProvider p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _RetouchCard(
            title: 'Soft Focus',
            subtitle: 'Gentle blur for dreamy effect',
            icon: Icons.blur_on,
            child: _SliderApplyRow(
              min: 1, max: 15, initial: 5,
              onApply: (v) => p.applySoftFocus(v.toInt()),
            ),
          ),
          const SizedBox(height: 8),
          _RetouchCard(
            title: 'Smooth Skin',
            subtitle: 'Edge-preserving skin smoothing',
            icon: Icons.face_retouching_natural,
            child: _ApplyButton(label: 'Apply', onTap: p.applySmoothSkin),
          ),
          const SizedBox(height: 8),
          _RetouchCard(
            title: 'Noise Clean',
            subtitle: 'Remove grain and noise',
            icon: Icons.grain,
            child: _SliderApplyRow(
              min: 1, max: 7, initial: 3,
              onApply: (v) => p.applyNoiseClean(v.toInt()),
            ),
          ),
          const SizedBox(height: 8),
          _RetouchCard(
            title: 'Edge Art',
            subtitle: 'Artistic edge detection',
            icon: Icons.tonality,
            child: _ApplyButton(label: 'Apply', onTap: p.applyEdgeArt),
          ),
          const SizedBox(height: 8),
          _RetouchCard(
            title: 'Sketch Style',
            subtitle: 'Stylized sketch effect',
            icon: Icons.draw_outlined,
            child: _ApplyButton(label: 'Apply', onTap: p.applySketchEdges),
          ),
        ],
      ),
    );
  }

  // ── Tab 5: Transform ──────────────────────────────────────────────────────
  Widget _buildToolsTab(EditorProvider p) {
    return SingleChildScrollView(
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
                  onTap: p.hasImage ? p.rotateRight : null),
              const SizedBox(width: 8),
              _TransformBtn(
                  icon: Icons.rotate_left, label: 'Rotate L',
                  onTap: p.hasImage ? p.rotateLeft : null),
              const SizedBox(width: 8),
              _TransformBtn(
                  icon: Icons.flip, label: 'Flip H',
                  onTap: p.hasImage ? p.flipHorizontal : null),
              const SizedBox(width: 8),
              _TransformBtn(
                  icon: Icons.flip, label: 'Flip V',
                  onTap: p.hasImage ? p.flipVertical : null),
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
              onPressed: p.hasImage ? p.startCrop : null,
              icon: const Icon(Icons.crop),
              label: const Text('✂  Start Crop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
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
