import 'package:flutter/material.dart';

/// Shared page-route builders so every screen transition feels consistent.

/// Fade + subtle upward slide — used for forward navigation.
PageRouteBuilder<T> fadeSlideRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 380),
}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final fade = Tween<double>(begin: 0, end: 1).animate(curved);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(curved);
      // Outgoing screen fades out slightly.
      final outFade = Tween<double>(begin: 1, end: 0.85).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
      );
      return FadeTransition(
        opacity: outFade,
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        ),
      );
    },
  );
}

/// Pure fade — used for title → level select.
PageRouteBuilder<T> fadeRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 500),
}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
