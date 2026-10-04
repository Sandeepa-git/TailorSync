import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/ui.dart';
import '../../config/env_config.dart';
import '../slide_captcha.dart';
import 'captcha_view_mobile.dart' if (dart.library.js_interop) 'captcha_view_web.dart';

/// Google reCAPTCHA v2 check for login / signup.
///
/// 1. Asks the backend if reCAPTCHA is enabled (`/auth/captcha-config`).
/// 2. Enabled  → shows an "I'm not a robot" box; tapping opens Google's real
///    widget (full screen, so image puzzles fit). The token goes to [onToken]
///    and must be sent to the backend, which verifies it with Google.
/// 3. Disabled / unreachable → falls back to the offline [SlideCaptcha].
class RecaptchaCheck extends StatefulWidget {
  final ValueChanged<String?> onToken; // token, or null when using the offline fallback
  final VoidCallback onReset;
  final bool enabled;

  const RecaptchaCheck({super.key, required this.onToken, required this.onReset, this.enabled = true});

  @override
  State<RecaptchaCheck> createState() => _RecaptchaCheckState();
}

enum _Mode { checking, recaptcha, fallback }

class _RecaptchaCheckState extends State<RecaptchaCheck> {
  _Mode _mode = _Mode.checking;
  bool _verified = false;
  String? _error;

  String get _base => EnvConfig.backendUrl;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final resp = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      )).get('$_base/auth/captcha-config');
      final enabled = resp.data is Map && resp.data['enabled'] == true;
      if (mounted) setState(() => _mode = enabled ? _Mode.recaptcha : _Mode.fallback);
    } catch (_) {
      if (mounted) setState(() => _mode = _Mode.fallback);
    }
  }

  Future<void> _openChallenge() async {
    if (!widget.enabled || _verified) return;
    HapticFeedback.selectionClick();
    setState(() => _error = null);
    final token = await showDialog<String>(
      context: context,
      useSafeArea: false,
      builder: (_) => _RecaptchaDialog(url: '$_base/auth/captcha-page'),
    );
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _verified = true);
      widget.onToken(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _Mode.checking:
        return const SizedBox(height: 4, child: LinearProgressIndicator(minHeight: 2));
      case _Mode.fallback:
        return SlideCaptcha(
          enabled: widget.enabled,
          onChanged: (ok) => ok ? widget.onToken(null) : widget.onReset(),
        );
      case _Mode.recaptcha:
        return _buildBox(context);
    }
  }

  Widget _buildBox(BuildContext context) {
    final cs = context.colors;
    final st = context.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: _verified ? st.success.withValues(alpha: 0.08) : cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: Radii.brMd,
            side: BorderSide(color: _verified ? st.success.withValues(alpha: 0.6) : cs.outlineVariant),
          ),
          child: InkWell(
            borderRadius: Radii.brMd,
            onTap: _verified ? null : _openChallenge,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _verified
                        ? Icon(Icons.check_box_rounded, key: const ValueKey('on'), color: st.success, size: 30)
                        : Icon(Icons.check_box_outline_blank_rounded,
                            key: const ValueKey('off'), color: cs.outline, size: 30),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      _verified ? 'Verified — you\'re not a robot' : 'I\'m not a robot',
                      style: context.text.titleSmall,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.security_rounded, color: cs.primary, size: 22),
                      Text('reCAPTCHA', style: context.text.labelSmall?.copyWith(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.xxs),
            child: Text(_error!, style: context.text.bodySmall?.copyWith(color: st.danger)),
          ),
      ],
    );
  }
}

/// Full-screen dialog hosting Google's widget. Pops with the token on success.
class _RecaptchaDialog extends StatefulWidget {
  final String url;
  const _RecaptchaDialog({required this.url});

  @override
  State<_RecaptchaDialog> createState() => _RecaptchaDialogState();
}

class _RecaptchaDialogState extends State<_RecaptchaDialog> {
  bool _loading = true;
  String? _error;
  int _reloadKey = 0;

  void _onMessage(String m) {
    if (!mounted) return;
    if (m == 'ready') {
      setState(() => _loading = false);
    } else if (m.startsWith('token:')) {
      Navigator.of(context).pop(m.substring(6));
    } else if (m == 'expired') {
      setState(() => _error = 'The check expired. Please tick the box again.');
    } else if (m.startsWith('error:')) {
      setState(() {
        _loading = false;
        _error = m == 'error:unsupported'
            ? 'reCAPTCHA is not supported on this device.'
            : 'Could not reach Google reCAPTCHA. Check your internet connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: const CloseButton(),
          title: const Text('Security check'),
          actions: [
            IconButton(
              tooltip: 'Reload',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => setState(() {
                _reloadKey++;
                _loading = true;
                _error = null;
              }),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_error != null)
              MaterialBanner(
                content: Text(_error!),
                leading: Icon(Icons.error_outline_rounded, color: context.status.danger),
                actions: [TextButton(onPressed: () => setState(() => _error = null), child: const Text('OK'))],
              ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(_reloadKey),
                child: buildCaptchaView(widget.url, _onMessage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
