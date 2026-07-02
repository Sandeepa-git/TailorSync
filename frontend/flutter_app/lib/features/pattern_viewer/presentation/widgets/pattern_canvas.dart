import 'package:flutter/material.dart';

class PatternCanvas extends StatelessWidget {
  const PatternCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      child: const CustomPaint(
        size: Size(300, 300),
        child: Center(child: Text('Pattern canvas with overlays')),
      ),
    );
  }
}
