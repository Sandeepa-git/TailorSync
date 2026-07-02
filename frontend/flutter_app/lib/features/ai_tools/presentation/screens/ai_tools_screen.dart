import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_provider.dart';

import 'package:go_router/go_router.dart';

class AiToolsScreen extends ConsumerWidget {
  const AiToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(aiProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tools'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(child: ElevatedButton(onPressed: () async {
      await api.predictMeasurements({'profile': {}});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI responded')));
    }, child: const Text('Call predict'))));
  }
}
