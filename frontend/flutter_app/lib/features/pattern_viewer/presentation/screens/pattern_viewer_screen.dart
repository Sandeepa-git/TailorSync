import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';

class PatternViewerScreen extends StatelessWidget {
  const PatternViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.architecture_rounded,
          title: 'Pattern Viewer',
          message: 'Interactive pattern previews will appear here.',
        ),
      ),
    );
  }
}
