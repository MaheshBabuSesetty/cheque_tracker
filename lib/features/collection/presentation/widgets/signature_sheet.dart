import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';
import 'signature_pad.dart';

/// Modal signature capture, opened from step 6's "Tap to sign" tile. Owns
/// its own [SignaturePadController] — strokes only exist while this sheet
/// is on screen, so "Use signature" exports the drawing to PNG bytes and
/// pops them back to the caller before the pad (and its strokes) are torn
/// down with the sheet.
class SignatureSheet extends StatefulWidget {
  const SignatureSheet({super.key});

  static Future<Uint8List?> show(BuildContext context) {
    return showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SignatureSheet(),
    );
  }

  @override
  State<SignatureSheet> createState() => _SignatureSheetState();
}

class _SignatureSheetState extends State<SignatureSheet> {
  final _controller = SignaturePadController();
  bool _hasInk = false;

  void _onChanged() => setState(() => _hasInk = _controller.hasInk);

  Future<void> _useSignature() async {
    final bytes = await _controller.exportPng();
    if (bytes != null && mounted) Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Signature', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17.5)),
              const SizedBox(height: 3),
              const Text(
                'Have the representative sign below.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 13),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withValues(alpha: 0.22)),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFFBFAF6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      SignaturePad(controller: _controller, onChanged: _onChanged),
                      if (!_hasInk)
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: Text('Sign here with your finger', style: TextStyle(color: AppColors.textFaint, fontSize: 12.5)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  TextButton(
                    onPressed: _hasInk
                        ? () => setState(() {
                              _controller.undo();
                              _hasInk = _controller.hasInk;
                            })
                        : null,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: const Text('Undo stroke', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF3A4552))),
                  ),
                  const SizedBox(width: 14),
                  TextButton(
                    onPressed: _hasInk
                        ? () => setState(() {
                              _controller.clear();
                              _hasInk = _controller.hasInk;
                            })
                        : null,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: const Text('Clear', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.danger)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              AppPrimaryButton(
                label: 'Use signature',
                onPressed: _hasInk ? _useSignature : null,
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
