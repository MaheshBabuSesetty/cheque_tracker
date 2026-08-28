import 'package:flutter/material.dart';

/// Caps content to a comfortable reading width and centers it horizontally.
///
/// Every screen in this app is a single-column, phone-oriented form or
/// list. Without this, running on a tablet (or a resized desktop/web
/// window) stretches that single column edge-to-edge — text fields and
/// buttons hundreds of pixels wide, list rows absurdly long, all the
/// whitespace on the sides instead of around the content.
///
/// Wrap the *inner* content of a full-bleed background `Container` with
/// this — not the `Container` itself — so header/footer background colors
/// and borders still span the full screen width while the actual content
/// (text, fields, cards) stays capped and centered, like a phone screen
/// floating in the middle of a wider one.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({super.key, required this.child, this.maxWidth = 560});

  final Widget child;

  /// ~560 comfortably fits every form field/card width already tuned for a
  /// ~400dp phone screen, with a little breathing room, without looking
  /// like a phone UI awkwardly shrunk into a tablet.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
