import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Android / iOS: loads the captcha page in a WebView and forwards its messages.
Widget buildCaptchaView(String url, void Function(String message) onMessage) =>
    _MobileCaptchaView(url: url, onMessage: onMessage);

class _MobileCaptchaView extends StatefulWidget {
  final String url;
  final void Function(String message) onMessage;
  const _MobileCaptchaView({required this.url, required this.onMessage});

  @override
  State<_MobileCaptchaView> createState() => _MobileCaptchaViewState();
}

class _MobileCaptchaViewState extends State<_MobileCaptchaView> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..enableZoom(false)
        ..addJavaScriptChannel('CaptchaChannel', onMessageReceived: (m) => widget.onMessage(m.message))
        ..setNavigationDelegate(NavigationDelegate(
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) widget.onMessage('error:load');
          },
        ))
        ..loadRequest(Uri.parse(widget.url));
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onMessage('error:unsupported'));
    }
  }

  @override
  Widget build(BuildContext context) =>
      _controller == null ? const SizedBox.shrink() : WebViewWidget(controller: _controller!);
}
