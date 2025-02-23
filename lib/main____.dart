import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text('MJPEG Stream')),
        body: Center(
          child: Mjpeg(
            stream: 'http://192.168.1.181:8081/video?t=${DateTime.now().millisecondsSinceEpoch}',
            isLive: true,
          ),
        ),
      ),
    );
  }
}
