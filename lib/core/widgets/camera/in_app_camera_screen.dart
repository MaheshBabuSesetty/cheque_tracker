import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../routing/page_transitions.dart';

/// Shape of the viewfinder frame drawn over the live preview.
enum CameraFrameShape { rect, circle }

/// Full-screen live camera capture UI — corner-bracket viewfinder frame,
/// a decorative sweeping scan line, and a manual shutter button. Replaces
/// launching the OS's native camera app (the old `image_picker` flow):
/// every document/photo capture in the app goes through this same screen,
/// framed differently per document type via [aspectRatio]/[shape].
///
/// Purely visual — unlike a live-OCR document scanner, this never reads
/// frames or auto-captures; the agent always taps the shutter themselves.
class InAppCameraScreen extends StatefulWidget {
  const InAppCameraScreen({
    super.key,
    required this.title,
    required this.guidance,
    this.aspectRatio = 4 / 3,
    this.shape = CameraFrameShape.rect,
    this.initialLens = CameraLensDirection.back,
    this.fillHeight = false,
  });

  final String title;
  final String guidance;
  final double aspectRatio;
  final CameraFrameShape shape;

  /// Which lens to open with — the flip button (when both exist) still
  /// lets the agent switch either way after that.
  final CameraLensDirection initialLens;

  /// When true, the frame's height fills the available vertical space
  /// between the top bar and the guidance text instead of being derived
  /// from [aspectRatio] — for documents like a cheque, whose true aspect
  /// ratio would otherwise leave a small landscape box floating in a lot
  /// of empty screen. [aspectRatio] still governs the frame's width cap.
  final bool fillHeight;

  /// Pushes the screen via the app's global [navKey] (rather than requiring
  /// a `BuildContext`) so context-free services/notifiers can launch it —
  /// see `lib/core/routing/app_router.dart`'s `navigatorKey` doc comment
  /// for why that pattern already exists in this app. Resolves to the
  /// captured [XFile], or `null` if the agent backed out.
  static Future<XFile?> show(
    GlobalKey<NavigatorState> navKey, {
    required String title,
    required String guidance,
    double aspectRatio = 4 / 3,
    CameraFrameShape shape = CameraFrameShape.rect,
    CameraLensDirection initialLens = CameraLensDirection.back,
    bool fillHeight = false,
  }) {
    return navKey.currentState!.push<XFile?>(
      AppPageRoute(
        page: InAppCameraScreen(
          title: title,
          guidance: guidance,
          aspectRatio: aspectRatio,
          shape: shape,
          initialLens: initialLens,
          fillHeight: fillHeight,
        ),
        transitionType: TransitionType.slide,
      ),
    );
  }

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  List<CameraDescription> _cameras = const [];
  late CameraLensDirection _lens = widget.initialLens;
  bool _torchOn = false;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFuture = _init();
  }

  Future<void> _init() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      final selected = _cameras.firstWhere(
        (c) => c.lensDirection == _lens,
        orElse: () => _cameras.first,
      );
      final controller = CameraController(selected, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _torchOn = false;
      });
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't open the camera. Check camera permission and try again.");
    }
  }

  bool get _hasBothLenses =>
      _cameras.any((c) => c.lensDirection == CameraLensDirection.back) &&
      _cameras.any((c) => c.lensDirection == CameraLensDirection.front);

  Future<void> _switchCamera() async {
    if (!_hasBothLenses) return;
    final old = _controller;
    _controller = null;
    setState(() {
      _lens = _lens == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
      _initializeFuture = _init();
    });
    await old?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeFuture = _init();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null) return;
    final next = !_torchOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _torchOn = next);
    } catch (_) {
      // Some devices/lenses don't support torch — leave state unchanged.
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(file);
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: widget.title,
              torchOn: _torchOn,
              showFlip: _hasBothLenses,
              onBack: () => Navigator.of(context).pop(),
              onToggleTorch: _toggleTorch,
              onFlip: _switchCamera,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: FutureBuilder<void>(
                      future: _initializeFuture,
                      builder: (context, snapshot) {
                        if (_error != null) return _ErrorState(message: _error!);
                        final controller = _controller;
                        if (controller == null || !controller.value.isInitialized) {
                          return const CircularProgressIndicator(color: AppColors.gold);
                        }
                        return _Viewfinder(
                          controller: controller,
                          aspectRatio: widget.aspectRatio,
                          shape: widget.shape,
                          guidance: widget.guidance,
                          fillHeight: widget.fillHeight,
                          availableHeight: constraints.maxHeight,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            _ShutterBar(capturing: _capturing, enabled: _controller != null, onCapture: _capture),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.torchOn,
    required this.showFlip,
    required this.onBack,
    required this.onToggleTorch,
    required this.onFlip,
  });

  final String title;
  final bool torchOn;
  final bool showFlip;
  final VoidCallback onBack;
  final VoidCallback onToggleTorch;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: onBack),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (showFlip)
            IconButton(icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white), onPressed: onFlip),
          IconButton(
            icon: Icon(torchOn ? Icons.flash_on : Icons.flash_off, color: torchOn ? AppColors.gold : Colors.white),
            onPressed: onToggleTorch,
          ),
        ],
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.controller,
    required this.aspectRatio,
    required this.shape,
    required this.guidance,
    this.fillHeight = false,
    this.availableHeight,
  });

  final CameraController controller;
  final double aspectRatio;
  final CameraFrameShape shape;
  final String guidance;

  /// See [InAppCameraScreen.fillHeight].
  final bool fillHeight;

  /// The height available to this widget (from the enclosing `Expanded`),
  /// used only when [fillHeight] is true.
  final double? availableHeight;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Capped so a tablet (or a resized desktop/web window) doesn't blow the
    // viewfinder up to an enormous frame — 85% still governs phone-sized
    // screens, this only kicks in once that would exceed a sensible size.
    final frameWidth = (screenWidth * 0.85).clamp(0, 420).toDouble();
    var frameHeight = shape == CameraFrameShape.circle ? frameWidth : frameWidth / aspectRatio;

    final maxHeight = availableHeight;
    if (fillHeight && shape != CameraFrameShape.circle && maxHeight != null) {
      // Reserve room below the frame for its 18px gap plus the two-line
      // guidance text, then let the frame claim the rest of the available
      // height — capped so it never shrinks below its aspect-ratio height.
      const reservedForGuidance = 76.0;
      final fitted = maxHeight - reservedForGuidance;
      if (fitted > frameHeight) frameHeight = fitted;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: frameWidth,
          height: frameHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: shape == CameraFrameShape.circle
                    ? const _CircleClipper()
                    : _RRectClipper(radius: 14),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: frameWidth,
                    height: frameWidth * controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
              IgnorePointer(
                child: ClipRect(
                  child: _ScanLine(color: AppColors.gold, circular: shape == CameraFrameShape.circle),
                ),
              ),
              CustomPaint(
                painter: shape == CameraFrameShape.circle
                    ? _CircleOutlinePainter(color: Colors.white.withValues(alpha: 0.85))
                    : _CornerBracketsPainter(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            guidance,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _RRectClipper extends CustomClipper<Path> {
  const _RRectClipper({required this.radius});
  final double radius;

  @override
  Path getClip(Size size) => Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper();

  @override
  Path getClip(Size size) => Path()..addOval(Offset.zero & size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Four L-shaped corner brackets around the frame — matches the viewfinder
/// style used elsewhere for document scanning, just without the live-OCR
/// behavior behind it.
class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter({required this.color, this.length = 22, this.strokeWidth = 3});

  final Color color;
  final double length;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void bracket(Offset corner, double dx, double dy) {
      canvas.drawLine(corner, corner + Offset(dx * length, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, dy * length), paint);
    }

    bracket(const Offset(0, 0), 1, 1);
    bracket(Offset(size.width, 0), -1, 1);
    bracket(Offset(0, size.height), 1, -1);
    bracket(Offset(size.width, size.height), -1, -1);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) => oldDelegate.color != color;
}

class _CircleOutlinePainter extends CustomPainter {
  const _CircleOutlinePainter({required this.color, this.strokeWidth = 3});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawOval(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _CircleOutlinePainter oldDelegate) => oldDelegate.color != color;
}

/// A thin gradient line sweeping top-to-bottom inside the frame, looping —
/// purely decorative (this screen never runs live OCR), matching the same
/// visual language as `CaptureTile`'s post-capture scanning overlay.
class _ScanLine extends StatefulWidget {
  const _ScanLine({required this.color, this.circular = false});

  final Color color;
  final bool circular;

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final t = _controller.value;
            final top = constraints.maxHeight * t;
            final fadeIn = (t / 0.08).clamp(0.0, 1.0);
            final fadeOut = ((1 - t) / 0.08).clamp(0.0, 1.0);
            final opacity = fadeIn < 1.0 ? fadeIn : (fadeOut < 1.0 ? fadeOut : 1.0);
            final horizontalInset = widget.circular ? constraints.maxWidth * 0.12 : 8.0;
            return Stack(
              children: [
                Positioned(
                  top: top,
                  left: horizontalInset,
                  right: horizontalInset,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.color.withValues(alpha: 0), widget.color, widget.color.withValues(alpha: 0)],
                        ),
                        boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ShutterBar extends StatelessWidget {
  const _ShutterBar({required this.capturing, required this.enabled, required this.onCapture});

  final bool capturing;
  final bool enabled;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: GestureDetector(
        onTap: enabled && !capturing ? onCapture : null,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: enabled ? 0.9 : 0.3), width: 3),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: enabled ? 1 : 0.3)),
            alignment: Alignment.center,
            child: capturing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.goldLink))
                : const Icon(Icons.camera_alt, color: AppColors.goldLink, size: 26),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 32),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
