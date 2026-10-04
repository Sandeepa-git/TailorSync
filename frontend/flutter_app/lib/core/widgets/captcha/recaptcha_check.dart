import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/ui.dart';
import '../../config/env_config.dart';
import 'captcha_view_mobile.dart' if (dart.library.js_interop) 'captcha_view_web.dart';

/// Google reCAPTCHA v2 "I'm not a robot" box, shown inline in the form.
///
/// 1. Asks the backend if reCAPTCHA is enabled (`/auth/captcha-config`).
/// 2. Enabled  → embeds Google's checkbox right here (it grows in place if
///    Google shows an image puzzle). The token goes to [onToken] and is sent
///    to the backend, which verifies it with Google.
/// 3. Disabled / unreachable → shows nothing; the server decides.
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
  static const double _boxHeight = 80;

  _Mode _mode = _Mode.checking;
  bool _loading = true;
  bool _verified = false;
  double _height = _boxHeight;
  String? _error;
  int _reloadKey = 0;
  Timer? _readyTimer;

  String get _base => EnvConfig.backendUrl;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final resp = await dio.get('$_base/auth/captcha-config');
      var enabled = resp.data is Map && resp.data['enabled'] == true;
      if (enabled) {
        // Make sure the widget page really exists on the server before showing it
        // (avoids showing a raw "Not Found" box while a deploy is in progress).
        final page = await dio.get<String>(
          '$_base/auth/captcha-page',
          options: Options(responseType: ResponseType.plain),
        );
        enabled = page.statusCode == 200 && (page.data ?? '').contains('g-recaptcha');
      }
      if (mounted) setState(() => _mode = enabled ? _Mode.recaptcha : _Mode.fallback);
      if (enabled) {
        _startReadyTimer();
      } else {
        _signalNoCaptcha();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _mode = _Mode.fallback);
        _signalNoCaptcha();
      }
    }
  }

  void _signalNoCaptcha() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onToken(null);
    });
  }

  void _startReadyTimer() {
    _readyTimer?.cancel();
    _readyTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && _loading && _mode == _Mode.recaptcha) {
        setState(() => _mode = _Mode.fallback);
        _signalNoCaptcha();
      }
    });
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    super.dispose();
  }

  void _onMessage(String m) {
    if (!mounted) return;
    if (m == 'ready') {
      _readyTimer?.cancel();
      setState(() => _loading = false);
    } else if (m.startsWith('height:')) {
      final h = double.tryParse(m.substring(7));
      if (h != null) setState(() => _height = h.clamp(60.0, 700.0));
    } else if (m.startsWith('token:')) {
      HapticFeedback.lightImpact();
      setState(() {
        _verified = true;
        _error = null;
        _height = _boxHeight;
      });
      widget.onToken(m.substring(6));
    } else if (m == 'expired') {
      setState(() {
        _verified = false;
        _error = 'That took a little while, so it timed out. Just tick the box once more.';
      });
      widget.onReset();
    } else if (m.startsWith('error:')) {
      setState(() {
        _loading = false;
        _verified = false;
        _error = m == 'error:unsupported'
            ? 'This check isn\'t available here.'
            : 'Hmm, we couldn\'t load the check. Make sure you\'re online, then tap Try again.';
      });
      widget.onReset();
      if (m == 'error:unsupported') {
        setState(() => _mode = _Mode.fallback);
        _signalNoCaptcha();
      }
    }
  }

  void _reload() {
    widget.onReset();
    setState(() {
      _reloadKey++;
      _loading = true;
      _verified = false;
      _error = null;
      _height = _boxHeight;
    });
    _startReadyTimer();
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _Mode.checking:
        return const SizedBox(height: 4, child: LinearProgressIndicator(minHeight: 2));
      case _Mode.fallback:
        // reCAPTCHA not available on the server: show nothing and let the
        // server decide (it only demands a token when reCAPTCHA is enabled).
        return const SizedBox.shrink();
      case _Mode.recaptcha:
        return _buildInline(context);
    }
  }

  Widget _buildInline(BuildContext context) {
    final cs = context.colors;
    final st = context.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: _height,
          child: Stack(
            children: [
              Positioned.fill(
                child: KeyedSubtree(
                  key: ValueKey(_reloadKey),
                  child: buildCaptchaView('$_base/auth/captcha-page', _onMessage),
                ),
              ),
              if (_loading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: Space.md),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: Radii.brSm,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                          ),
                          const SizedBox(width: Space.sm),
                          Text('Getting your quick check ready…', style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_error != null)
          Row(
            children: [
              Expanded(child: Text(_error!, style: context.text.bodySmall?.copyWith(color: st.danger))),
              TextButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ),
      ],
    );
  }
}
