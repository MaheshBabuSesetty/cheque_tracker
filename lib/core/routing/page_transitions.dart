import 'package:flutter/material.dart';

enum TransitionType { fade, slide, scale }

/// Centralized animation timing so every custom transition in the app feels
/// consistent, and so it can be tuned from one place.
class TransitionConstants {
  const TransitionConstants._();

  static const Duration duration = Duration(milliseconds: 320);
  static const Curve curve = Curves.easeInOutCubic;
}

/// Drop-in replacement for `MaterialPageRoute` when a non-default
/// transition is wanted. Plain `MaterialPageRoute`/`Navigator.push` is still
/// fine for simple pushes that don't need a custom effect.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required this.page,
    this.transitionType = TransitionType.fade,
    super.settings,
  }) : super(
          transitionDuration: TransitionConstants.duration,
          reverseTransitionDuration: TransitionConstants.duration,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: TransitionConstants.curve);
            switch (transitionType) {
              case TransitionType.fade:
                return FadeTransition(opacity: curved, child: child);
              case TransitionType.slide:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                );
              case TransitionType.scale:
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
                  child: FadeTransition(opacity: curved, child: child),
                );
            }
          },
        );

  final Widget page;
  final TransitionType transitionType;
}
