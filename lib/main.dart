import 'dart:io';
import 'dart:convert';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

setAppSize(double x, double y, double width, double height) {
  setWindowFrame(Rect.fromLTWH(x, y, width, height));
}

const port = 8765;
bool isUsingVlc = false;
void main(List<String> args) {
  final config = AppConfig(
    width: 0,
    height: 0,
    x: 100,
    y: 100,
    mediaUrl: "",
  );
  if (args.length > 4) {
    config.mediaUrl = args[0];
    config.width = double.parse(args[1]);
    config.height = double.parse(args[2]);
    config.x = double.parse(args[3]);
    config.y = double.parse(args[4]);
  }

  if (Platform.isWindows || Platform.isLinux) {
    isUsingVlc = true;
    DartVLC.initialize();
  }

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
  late AppConfig mediaConfig;
  HttpServer? server;
  final player = Player(id: 69420);
  bool isVideo = false;

  @override
  void initState() {
    super.initState();
    mediaConfig = widget.config.clone();
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
    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    await for (var request in server) {
      if (request.method == "POST") {
        // Read the request body as a JSON object
        String content = await utf8.decoder.bind(request).join();
        var json = jsonDecode(content);
        int width = json["width"] ?? 0;
        int height = json['height'] ?? 0;
        int x = json['x'] ?? 0;
        int y = json['y'] ?? 0;
        final mediaUrl = json['media'] ?? '';

        if (width != 0 && height != 0 && x != 0 && y != 0) {
          setAppSize(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble());
        }
        if (mediaUrl.isNotEmpty) {
          setState(() {
            mediaConfig.mediaUrl = mediaUrl;
          });
        }
      }
      request.response
        ..headers.contentType = ContentType("text", "plain", charset: "utf-8")
        ..write('OK')
        ..close();
    }
  }

  // String lastMediaUrl = "";
  // void viewWeb(url) async {
  //   if (lastMediaUrl == url) {
  //     return;
  //   }
  //   final webview = await WebviewWindow.create();
  //   lastMediaUrl = url;
  //   webview.launch(url);
  // }

  Widget displayMedia() {
    final mediaUrl = mediaConfig.mediaUrl;
    if (mediaUrl.isEmpty) {
      return Image.asset('assets/empty.jpg', fit: BoxFit.cover);
    }
    if (mediaUrl.endsWith(".mp4") || mediaUrl.contains('googlevideo.com')) {
      player.open(
        Media.network(mediaConfig.mediaUrl),
      );
      return Video(
        player: player,
        scale: 1.0, // default
        showControls: true, // default
      );
    }
    if (mediaUrl.startsWith("http")) {
      return Image.network(
        mediaUrl,
        fit: BoxFit.fitWidth,
      );
    }
    return Image.file(
      File(mediaUrl),
      fit: BoxFit.fitWidth,
    );
  }

  String getYoutubeId(String url) {
    final RegExp exp =
        RegExp(r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*');
    final match = exp.firstMatch(url);
    debugPrint('match.groupCount: ${match?.groupCount ?? ""}');
    if (match != null && match.groupCount > 0) {
      return match.group(7) ?? '';
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: displayMedia(),
        ),
      ),
    );
  }
}
