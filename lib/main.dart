// // Copyright 2013 The Flutter Authors. All rights reserved.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.
//
// // ignore_for_file: public_member_api_docs
//
// import 'package:flutter/material.dart';
// import 'package:todo_drag_drop/urls.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// void main() => runApp(const MaterialApp(home: WebViewExample()));
//
// class WebViewExample extends StatefulWidget {
//   const WebViewExample({super.key});
//
//   @override
//   State<WebViewExample> createState() => _WebViewExampleState();
// }
//
// class _WebViewExampleState extends State<WebViewExample> {
//   late final WebViewController controller;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // #docregion webview_controller
//     controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0x00000000))
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onProgress: (int progress) {
//             // Update loading bar.
//           },
//           onPageStarted: (String url) {},
//           onPageFinished: (String url) {},
//           onWebResourceError: (WebResourceError error) {},
//           onNavigationRequest: (NavigationRequest request) {
//             if (request.url.startsWith('https://www.youtube.com/')) {
//               return NavigationDecision.prevent;
//             }
//             return NavigationDecision.navigate;
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(Urls.auth1));
//     // #enddocregion webview_controller
//   }
//
//   // #docregion webview_widget
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Flutter Simple Example')),
//       body: WebViewWidget(controller: controller),
//     );
//   }
// // #enddocregion webview_widget
// }
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:todo_drag_drop/api/client.dart';
import 'package:todo_drag_drop/models/task.dart';
import 'package:todo_drag_drop/top_page.dart';
import 'package:todo_drag_drop/urls.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO Drag Drop',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'TODO Drag Drop'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double webViewHeight = 1000;
  String state = "";

  final _cookieManager = WebViewCookieManager();
  final webViewController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setUserAgent('random')
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {},
        onPageStarted: (String url) {
          debugPrint("start:$url");
        },
        onPageFinished: (String url) {
          debugPrint("finish:$url");
        },
        onWebResourceError: (WebResourceError error) {
          debugPrint(error.toString());
        },
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadRequest(Uri.parse(Urls.auth1));

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    final codeUnits = List.generate(length, (index) {
      final n = rand.nextInt(chars.length);
      return chars.codeUnitAt(n);
    });
    return String.fromCharCodes(codeUnits);
  }

  void _showModal(Uri uri) async {
    // var returnObject = await webViewController
    //     .runJavaScriptReturningResult("document.documentElement.scrollHeight;");
    // var returnStr = returnObject.toString();
    // debugPrint(returnStr);
    // webViewHeight = double.parse(returnStr);
    webViewController.loadRequest(uri);
    webViewController.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {},
        onPageStarted: (String url) {
          debugPrint("start:$url");
        },
        onPageFinished: (String url) async {
          final uri = Uri.parse(url);
          if (url.contains("google")) {
            final accessToken =
                await Client.createAccessTokenFromCallbackUri(uri, state);
            debugPrint("accesstoken:$accessToken");
            if (!mounted) return;
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const ReorderableApp(),
                ));
          }
          debugPrint("finish:$url");
        },
        onWebResourceError: (WebResourceError error) {
          debugPrint(error.toString());
        },
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
      ),
    );
    debugPrint(await webViewController.currentUrl());
    showModalBottomSheet(
        enableDrag: true,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: SingleChildScrollView(
              child: SizedBox(
                height: webViewHeight,
                child: WebViewWidget(
                  controller: webViewController,
                ),
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                _showModal(Uri.parse(Urls.signIn));
              },
              child: const Text("SignIn"),
            ),
            TextButton(
              onPressed: () {
                _showModal(Uri.parse("https://dida365.com/signin"));
              },
              child: const Text("365SignIn"),
            ),
            TextButton(
              onPressed: () {
                state = _randomString(40);
                Uri uri = Uri(
                  scheme: 'https',
                  host: 'api.ticktick.com',
                  path: '/oauth/custom_authorize',
                  queryParameters: {
                    'scope': 'tasks:read',
                    'client_id': Client.clientID,
                    'state': state,
                    'redirect_uri': 'https://www.google.com/',
                    'response_type': 'code',
                  },
                );
                _showModal(uri);
              },
              child: const Text("Auth"),
            ),
            TextButton(
              onPressed: () {
                state = _randomString(40);
                Uri uri = Uri(
                  scheme: 'https',
                  host: 'dida365.com',
                  path: '/oauth/authorize',
                  queryParameters: {
                    'scope': 'tasks:read',
                    'client_id': Client.clientID,
                    'state': state,
                    'redirect_uri': 'https://www.google.com/',
                    'response_type': 'code',
                  },
                );
                _showModal(uri);
              },
              child: const Text("365Auth"),
            ),
            TextButton(
              onPressed: () async {
                debugPrint("aaa");
                final accessToken = await Client.getAccessToken() ??
                    "3429f053-1ae5-425c-8c39-3937d86adaae";
                debugPrint("[token]$accessToken");
                var a = await Client.fetchTask(
                    "3429f053-1ae5-425c-8c39-3937d86adaae");
                debugPrint("bbb");
              },
              child: const Text("FetchTask"),
            ),
            TextButton(
              onPressed: () async {
                Future<Task> fetchTask() async {
                  final accessToken = await Client.getAccessToken() ??
                      "3429f053-1ae5-425c-8c39-3937d86adaae";
                  final response = await http.get(
                      Uri.parse(
                          'https://api.ticktick.com/open/v1/project/{projectId}/task/{taskId}'),
                      headers: {"Authorization": "Bearer  $accessToken"});
                  if (response.statusCode == 200) {
                    debugPrint(response.reasonPhrase);
                    return Task.fromJson(jsonDecode(response.body));
                  } else {
                    debugPrint(response.statusCode.toString());
                    throw Exception('Failed to load album');
                  }
                }

                fetchTask();
              },
              child: const Text("http"),
            ),
            TextButton(
                onPressed: () async {
                  final accessToken = await Client.getAccessToken() ??
                      "3429f053-1ae5-425c-8c39-3937d86adaae";
                  debugPrint("[token]$accessToken");
                  var a = await Client.createTask(
                      "3429f053-1ae5-425c-8c39-3937d86adaae");
                },
                child: const Text("createTask"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _cookieManager.clearCookies(),
        child: const Icon(Icons.delete),
      ),
    );
  }
}
