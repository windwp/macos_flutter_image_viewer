import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

setAppSize(double x, double y, double width, double height) {
  setWindowFrame(Rect.fromLTWH(x, y, width, height));
}

const PORT = 87650;
void main(List<String> args) {
  final config = AppConfig(
    width: double.parse(args[0]),
    height: double.parse(args[1]),
    x: double.parse(args[2]),
    y: double.parse(args[3]),
    mediaUrl: args[4],
  );

  debugPrint('config: $config');
  runApp(MyApp(config: config));
}

class AppConfig {
  double width;
  double height;
  double x;
  double y;
  String mediaUrl;
  AppConfig(
      {required this.width,
      required this.height,
      required this.x,
      required this.y,
      required this.mediaUrl});
  clone() {
    return AppConfig(width: width, height: height, x: x, y: y, mediaUrl: mediaUrl);
  }
}

class MyApp extends StatelessWidget {
  final AppConfig config;
  const MyApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImageViewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(config: config),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final AppConfig config;
  const MyHomePage({super.key, required this.config});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AppConfig currentConfig;
  bool isInit = false;
  HttpServer? server;

  @override
  void initState() {
    super.initState();
    currentConfig = widget.config.clone();
    listenPort();
  }

  @override
  void dispose() {
    super.dispose();
    if (server != null) {
      server!.close();
    }
  }

  listenPort() async {
    if (isInit) return;
    isInit = true;
    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, PORT);
    await for (var request in server) {
      if (request.method == "GET") {
        final width = request.uri.queryParameters['width'] ?? '';
        final height = request.uri.queryParameters['height'] ?? '';
        final x = request.uri.queryParameters['x'] ?? '';
        final y = request.uri.queryParameters['y'] ?? '';
        final image = request.uri.queryParameters['image'] ?? '';
        if (width.isNotEmpty && height.isNotEmpty && x.isNotEmpty && y.isNotEmpty) {
          setAppSize(double.parse(x), double.parse(y), double.parse(width), double.parse(height));
        }
        if (image.isNotEmpty) {
          setState(() {
            currentConfig.mediaUrl = image;
          });
        }
      }
      request.response
        ..headers.contentType = ContentType("text", "plain", charset: "utf-8")
        ..write('OK')
        ..close();
    }
  }

  Widget displayImage() {
    if (currentConfig.mediaUrl.isEmpty) {
      return Image.asset('assets/empty.jpg', fit: BoxFit.cover);
    }
    if (currentConfig.mediaUrl.startsWith("http")) {
      return Image.network(
        currentConfig.mediaUrl,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(currentConfig.mediaUrl),
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: displayImage(),
        ),
      ),
    );
  }
}
