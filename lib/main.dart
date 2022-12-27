import 'dart:io';
import 'dart:convert';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:extended_image/extended_image.dart';
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
    backgroundColor: Colors.black,
  );
  if (args.length > 4) {
    config.mediaUrl = args[0];
    config.width = double.parse(args[1]);
    config.height = double.parse(args[2]);
    config.x = double.parse(args[3]);
    config.y = double.parse(args[4]);
  }

  if (args.length > 5) {
    config.backgroundColor = hexToColor(args[5]);
  }

  if (Platform.isWindows || Platform.isLinux) {
    isUsingVlc = true;
    DartVLC.initialize();
  }

  runApp(MyApp(config: config));
}

Color hexToColor(String hex) {
  try {
    int val = int.parse(hex.substring(1), radix: 16);
    int r = (val >> 16) & 0xFF;
    int g = (val >> 8) & 0xFF;
    int b = val & 0xFF;
    return Color.fromRGBO(r, g, b, 1.0);
  } catch (e) {
    return Colors.black;
  }
}

class AppConfig {
  double width;
  double height;
  double x;
  double y;
  String mediaUrl;
  Color backgroundColor;
  AppConfig(
      {required this.width,
      required this.height,
      required this.x,
      required this.y,
      required this.mediaUrl,
      required this.backgroundColor});

  clone() {
    return AppConfig(
        width: width,
        height: height,
        x: x,
        y: y,
        mediaUrl: mediaUrl,
        backgroundColor: backgroundColor);
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
        if (mediaUrl.isNotEmpty && mediaConfig.mediaUrl != mediaUrl) {
          isVideo = false;
          if (mediaUrl.endsWith(".mp4") || mediaUrl.contains('googlevideo.com')) {
            isVideo = true;
            if (mediaUrl.startsWith("http")) {
              player.open(
                Media.network(mediaUrl),
              );
            } else {
              player.open(Media.file(File(mediaUrl)));
            }
          }
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

  Widget displayMedia() {
    final mediaUrl = mediaConfig.mediaUrl;
    if (mediaUrl.isEmpty) {
      return Image.asset(
        'assets/empty.jpg',
        fit: BoxFit.cover,
      );
    }
    if (isVideo) {
      return Video(
        player: player,
        scale: 1.0, // default
        fillColor: mediaConfig.backgroundColor,
        showControls: true, // default
      );
    } else {
      player.stop();
    }
    if (mediaUrl.startsWith("http")) {
      return ExtendedImage.network(
        mediaUrl,
        fit: BoxFit.fitWidth,
        mode: ExtendedImageMode.gesture,
        initGestureConfigHandler: (state) {
          return GestureConfig(
            minScale: 0.9,
            animationMinScale: 0.7,
            maxScale: 3.0,
            animationMaxScale: 3.5,
            speed: 1.0,
            inertialSpeed: 100.0,
            initialScale: 1.0,
            inPageView: false,
            initialAlignment: InitialAlignment.center,
          );
        },
      );
    }
    return ExtendedImage.file(
      File(mediaUrl),
      width: mediaConfig.width,
      height: mediaConfig.height,
      fit: BoxFit.fitWidth,
      mode: ExtendedImageMode.gesture,
      initGestureConfigHandler: (state) {
        return GestureConfig(
          minScale: 0.9,
          animationMinScale: 0.7,
          maxScale: 3.0,
          animationMaxScale: 3.5,
          speed: 1.0,
          inertialSpeed: 100.0,
          initialScale: 1.0,
          inPageView: false,
          initialAlignment: InitialAlignment.center,
        );
      },
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
      backgroundColor: mediaConfig.backgroundColor,
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
