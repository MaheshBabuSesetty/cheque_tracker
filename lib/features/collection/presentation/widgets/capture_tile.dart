import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A tappable capture target for a photo (representative photo, Emirates ID
/// front/back, cheque copy). Shows the captured image once [imagePath] is
/// set, otherwise a dashed placeholder with [icon] + [label]. [scanning]
/// overlays the OCR scanline effect used while the Emirates ID front is
/// being read.
class CaptureTile extends StatelessWidget {
  const CaptureTile({
    super.key,
    required this.imagePath,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filledLabel,
    this.aspectRatio,
    this.circular = false,
    this.size,
    this.scanning = false,
  });

  final String? imagePath;
  final Widget icon;
  final String label;
  final String? filledLabel;
  final VoidCallback onTap;
  final double? aspectRatio;
  final bool circular;
  final double? size;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final filled = imagePath != null;
    final borderColor = filled ? const Color(0xFF05744F) : Colors.black.withValues(alpha: 0.2);
    final bg = filled ? const Color(0xFFEEF8F2) : const Color(0xFFFBFAF6);
    final radius = circular ? null : BorderRadius.circular(11);

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: radius,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        color: bg,
        image: filled
            ? DecorationImage(image: FileImage(File(imagePath!)), fit: BoxFit.cover)
            : null,
      ),
      child: filled
          ? (circular || filledLabel == null
              ? null
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 7),
                    color: Colors.black.withValues(alpha: 0.62),
                    child: Text(
                      filledLabel!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ))
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  if (!circular) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );

    if (scanning) {
      content = ClipRRect(
        borderRadius: circular ? BorderRadius.circular(1000) : (radius ?? BorderRadius.zero),
        child: Stack(
          fit: StackFit.expand,
          children: [content, const _ScanlineOverlay()],
        ),
      );
    }

    final tile = aspectRatio != null
        ? AspectRatio(aspectRatio: aspectRatio!, child: content)
        : SizedBox(width: size, height: size, child: content);

    return GestureDetector(onTap: onTap, child: tile);
  }
}

class _ScanlineOverlay extends StatefulWidget {
  const _ScanlineOverlay();

  @override
  State<_ScanlineOverlay> createState() => _ScanlineOverlayState();
}

class _ScanlineOverlayState extends State<_ScanlineOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final top = constraints.maxHeight * (0.04 + _controller.value * 0.88);
            return Stack(
              children: [
                Positioned(
                  top: top,
                  left: constraints.maxWidth * 0.06,
                  right: constraints.maxWidth * 0.06,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.7), blurRadius: 6, spreadRadius: 1)],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
