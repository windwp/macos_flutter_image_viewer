import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:developer';
import 'package:menubar/menubar.dart';
import 'package:window_size/window_size.dart';

import 'package:args/args.dart';

const PORT = 8765;

 void mLogger(dynamic obj){
  print(inspect(obj));
}

void main(List<String> args) {
  var parser = ArgParser();
  parser.addOption('width', defaultsTo: '300');
  parser.addOption('height', defaultsTo: '300');
  parser.addOption('x', defaultsTo: '1150');
  parser.addOption('y', defaultsTo: '30');
  parser.addOption('image', defaultsTo: '');
  final result = parser.parse(args);
  runApp(MyApp(
      width: double.parse(result['width']),
      height: double.parse(result['height']),
      x: double.parse(result['x']),
      y: double.parse(result['y']),
      image: result['image']
      ));
}

class MyApp extends StatelessWidget {
  MyApp({this.width, this.height, this.x, this.y, this.image});
  final String image;
  final double width;
  final double height;
  final double x;
  final double y;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(
        title: 'Flutter Image viewer',
        width: this.width,
        height: this.height,
        x: this.x,
        y: this.y,
        image: this.image,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(
      {Key key,
      this.title,
      this.width,
      this.height,
      this.x,
      this.y,
      this.image})
      : super(key: key);
  final String title;
  final String image;
  final double width;
  final double height;
  final double x;
  final double y;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String url = "";
  bool isInit=false;
  @override
  void initState() {
    super.initState();
    this.url=this.widget.image;
    setAppSize(this.widget.x,this.widget.y,this.widget.width,this.widget.height);
    listenPort();
  }

  listenPort() async {
    if(this.isInit) return;
    this.isInit=true;
    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, PORT);
    await for (var request in server) {
      if (request.method == "GET") {
        final width = request.uri.queryParameters['width'] ?? '';
        final height = request.uri.queryParameters['height'] ?? '';
        final x = request.uri.queryParameters['x'] ?? '';
        final y = request.uri.queryParameters['y'] ?? '';
        final image = request.uri.queryParameters['image'] ?? '';
        if (width.isNotEmpty &&
            height.isNotEmpty &&
            x.isNotEmpty &&
            y.isNotEmpty) {
          setAppSize(double.parse(x), double.parse(y), double.parse(width),
              double.parse(height));
        }
        if (image.isNotEmpty) {
          setState(() {
            url = image;
          });
        }
      }
      request.response
        ..headers.contentType =
            new ContentType("text", "plain", charset: "utf-8")
        ..write('OK')
        ..close();
    }
  }

  setAppSize(double x, double y, double width, double height) {
    setWindowFrame(Rect.fromLTWH(x, y, width, height));
  }

  checkWindowSize() async {
    // var data = await getWindowMinSize();
    // var info = await getWindowInfo();
    // var rect = Rect.fromLTWH(100, 100, 300, 300);
    // setWindowFrame(rect);
    // setApplicationMenu([]);
  }

  Widget displayImage() {
    if (url.isEmpty) {
      return SizedBox();
    }
    return Image.file(
      File(url),
      fit: BoxFit.fill,
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: displayImage(),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Add your onPressed code here!
      //     checkWindowSize();
      //   },
      //   child: Icon(Icons.navigation),
      //   backgroundColor: Colors.green,
      // ),
    );
  }
}
