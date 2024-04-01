import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  bool _enableWebViewGesture = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;

      // Determine if the app bar is fully collapsed and update state accordingly
      if (offset >= kToolbarHeight) {
        setState(() { _enableWebViewGesture = true; });
      } else {
        setState(() { _enableWebViewGesture = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    var topBarWidget = FlexibleSpaceBar(
      title: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return const Text(
            'TITLE',
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          );
        }
      ),
      titlePadding: const EdgeInsetsDirectional.only(start: 0, bottom: 16),
      background: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.inversePrimary
        ),
      ),
    );

    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            pinned: false,
            snap: false,
            floating: false,
            expandedHeight: kToolbarHeight,
            flexibleSpace: topBarWidget,
          ),
        ];
      },
      body: InAppWebView(
        key: webViewKey,
        initialUrlRequest: URLRequest(url: WebUri('https://en.m.wikipedia.org')),
        gestureRecognizers: _enableWebViewGesture
          ? (Set()..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer())))
          : null,
        onWebViewCreated: (controller) async {
          webViewController = controller;
          webViewController?.addJavaScriptHandler(handlerName: 'scrollToTopHandler', callback: (args) {
            setState(() { _enableWebViewGesture = false; });
          });
        },
        onLoadStop: (controller, url) {
          controller.evaluateJavascript(source: """
            window.onscroll = function() {
              if (window.pageYOffset === 0) {
                window.flutter_inappwebview.callHandler('scrollToTopHandler');
              }
            };
          """);
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
