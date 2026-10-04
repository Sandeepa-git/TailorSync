import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TailorSyncPasswordRequirements extends StatelessWidget {
  final String password;

  const TailorSyncPasswordRequirements({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final hasLength = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$&*~]'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password requirements:',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _RequirementItem(label: '8+ characters', isMet: hasLength),
            _RequirementItem(label: 'Uppercase', isMet: hasUpper),
            _RequirementItem(label: 'Lowercase', isMet: hasLower),
            _RequirementItem(label: 'Number', isMet: hasNumber),
            _RequirementItem(label: 'Special character', isMet: hasSpecial),
          ],
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RequirementItem({
    required this.label,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMet ? const Color(0xFF2E7D32) : AppTheme.textCaption.withValues(alpha: 0.7);
    final icon = isMet ? Icons.check_circle : Icons.radio_button_unchecked;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: color,
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
