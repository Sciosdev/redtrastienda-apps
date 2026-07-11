import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_loader_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Webview in-app genérico para páginas públicas de ANPEC (R-Conéctate).
/// Patrón de BlogScreen sin su lógica de expulsión (que redirige al dashboard
/// cualquier URL que no contenga 'app/').
class AnpecWebviewScreen extends StatefulWidget {
  final String url;
  final String title;

  const AnpecWebviewScreen({super.key, required this.url, required this.title});

  @override
  State<AnpecWebviewScreen> createState() => _AnpecWebviewScreenState();
}

class _AnpecWebviewScreenState extends State<AnpecWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoadingFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (!_isLoadingFinished && mounted) {
              setState(() => _isLoadingFinished = true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    _controller.setBackgroundColor(Theme.of(context).highlightColor);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.title,
          centerTitle: true,
          onBackPressed: _handleBack,
        ),
        body: Stack(children: [
          WebViewWidget(controller: _controller),
          if (!_isLoadingFinished) const Center(child: CustomLoaderWidget()),
        ]),
      ),
    );
  }
}
