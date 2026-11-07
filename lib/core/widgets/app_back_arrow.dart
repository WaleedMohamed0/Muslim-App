import 'package:flutter/material.dart';

/// A consistently oriented back-style arrow used for navigation affordances.
class AppBackArrow extends StatelessWidget {
  const AppBackArrow({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(
    Icons.arrow_back_ios_new_rounded,
    textDirection: TextDirection.ltr,
    size: size,
    color: color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black),
  );
}
