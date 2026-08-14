import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/theme/app_colors.dart';

/// Imperative handle for [SignaturePad] — lets the parent screen trigger
/// undo/clear and export the drawn strokes as PNG bytes without the pad
/// needing to know about any of that itself (the pad only knows how to
/// draw).
class SignaturePadController {
  _SignaturePadState? _state;

  void _attach(_SignaturePadState state) => _state = state;
  void _detach(_SignaturePadState state) {
    if (_state == state) _state = null;
  }

  bool get hasInk => _state?._strokes.isNotEmpty ?? false;
  void undo() => _state?._undo();
  void clear() => _state?._clear();
  Future<Uint8List?> exportPng() async => _state?._exportPng();
}

/// Finger-drawn signature capture: a `GestureDetector` collecting stroke
/// points, painted with a `CustomPainter`. Mirrors the design's HTML
/// `<canvas>` signature pad.
class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key, required this.controller, this.onChanged});

  final SignaturePadController controller;
  final VoidCallback? onChanged;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    super.dispose();
  }

  void _start(Offset p) {
    setState(() => _strokes.add([p]));
    widget.onChanged?.call();
  }

  void _move(Offset p) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.add(p));
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
    widget.onChanged?.call();
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(_strokes.clear);
    widget.onChanged?.call();
  }

  Future<Uint8List?> _exportPng() async {
    if (_strokes.isEmpty) return null;
    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: ColoredBox(
        color: Colors.white,
        child: GestureDetector(
          onPanStart: (details) => _start(details.localPosition),
          onPanUpdate: (details) => _move(details.localPosition),
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: _SignaturePainter(_strokes),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
