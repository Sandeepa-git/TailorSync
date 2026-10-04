import 'package:flutter/material.dart';

import '../../ui/components/ts_button.dart';

/// Legacy entry point kept for existing call sites – now renders the new
/// [TsButton] (press scale, haptics, loading morph).
class TailorSyncButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final IconData? icon;

  const TailorSyncButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TsButton(label: text, onPressed: onPressed, loading: isLoading, success: isSuccess, icon: icon);
  }
}
