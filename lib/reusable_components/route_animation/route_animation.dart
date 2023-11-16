import 'package:flutter/material.dart';

Route routeFromBottom({required Widget page, bool opaque = true}) {
  return PageRouteBuilder(
    opaque: opaque,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.linearToEaseOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

Route routeFadeIn({required Widget page, bool opaque = true}) {
  return PageRouteBuilder(
    opaque: opaque,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.decelerate,
          ),
        ),
        child: child,
      );
    },
  );
}
