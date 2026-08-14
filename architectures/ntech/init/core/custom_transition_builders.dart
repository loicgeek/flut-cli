import 'package:flutter/material.dart';

// Build one transition builder for all routes.
// Swap the return statement to change the global transition style.
RouteTransitionsBuilder get customTransitionBuilder =>
    (context, animation, secondaryAnimation, child) {
      // Uncomment to disable all transitions:
      // return child;
      return FadeTransition(opacity: animation, child: child);
    };

