import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Flutter web: loads the captcha page in an <iframe> and listens for the
/// `captcha|...` messages it posts to this window.
Widget buildCaptchaView(String url, void Function(String message) onMessage) =>
    _WebCaptchaView(url: url, onMessage: onMessage);

int _viewCounter = 0;

class _WebCaptchaView extends StatefulWidget {
  final String url;
  final void Function(String message) onMessage;
  const _WebCaptchaView({required this.url, required this.onMessage});

  @override
  State<_WebCaptchaView> createState() => _WebCaptchaViewState();
}

class _WebCaptchaViewState extends State<_WebCaptchaView> {
  late final String _viewType = 'captcha-frame-${_viewCounter++}';
  late final String _origin = Uri.parse(widget.url).origin;
  JSFunction? _listener;

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return web.HTMLIFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });
    _listener = ((web.Event event) {
      final msg = event as web.MessageEvent;
      if (msg.origin != _origin) return;
      final data = msg.data;
      if (data == null || !data.isA<JSString>()) return;
      final text = (data as JSString).toDart;
      if (text.startsWith('captcha|')) widget.onMessage(text.substring('captcha|'.length));
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void dispose() {
    if (_listener != null) web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
