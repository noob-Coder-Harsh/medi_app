import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/i18n.dart';
import '../../../core/link_opener.dart';
import '../../../core/theme.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';

/// In-app browser for public web pages (privacy, terms, contact/data).
class StaffWebPage extends ConsumerStatefulWidget {
  const StaffWebPage({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  ConsumerState<StaffWebPage> createState() => _StaffWebPageState();
}

class _StaffWebPageState extends ConsumerState<StaffWebPage> {
  WebViewController? _controller;
  var _loading = true;
  var _failed = false;
  var _progress = 0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (!mounted) return;
              setState(() {
                _loading = true;
                _failed = false;
                _progress = 0;
              });
            },
            onProgress: (int value) {
              if (!mounted) return;
              setState(() => _progress = value);
            },
            onPageFinished: (_) {
              if (!mounted) return;
              setState(() {
                _loading = false;
                _progress = 100;
              });
            },
            onWebResourceError: (_) {
              if (!mounted) return;
              setState(() {
                _loading = false;
                _failed = true;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
      _controller = controller;
    } catch (_) {
      _failed = true;
      _loading = false;
    }
  }

  Future<void> _openExternal() async {
    await ref.read(linkOpenerProvider).open(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final controller = _controller;

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: widget.title,
        actions: <Widget>[
          IconButton(
            tooltip: t('MORE.OPEN_IN_BROWSER'),
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_browser),
          ),
        ],
      ),
      body: controller == null || _failed
          ? _Fallback(
              url: widget.url,
              onOpen: _openExternal,
            )
          : Stack(
              children: <Widget>[
                WebViewWidget(controller: controller),
                if (_loading)
                  LinearProgressIndicator(
                    value: _progress > 0 && _progress < 100
                        ? _progress / 100
                        : null,
                    minHeight: 2,
                  ),
              ],
            ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.url, required this.onOpen});

  final String url;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              t('MORE.WEB_UNAVAILABLE'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: AppTheme.touchTarget,
              child: FilledButton(
                onPressed: onOpen,
                child: Text(t('MORE.OPEN_IN_BROWSER')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
