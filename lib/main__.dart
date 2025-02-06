import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoStreamScreen(),
    );
  }
}

class VideoStreamScreen extends StatefulWidget {
  const VideoStreamScreen({super.key});

  @override
  State<VideoStreamScreen> createState() => _VideoStreamScreenState();
}

class _VideoStreamScreenState extends State<VideoStreamScreen> {
  late VlcPlayerController _controller;
  final String rtspUrl = "rtsp://192.168.1.181:8554/live"; // ✅ Cambia con il tuo URL

  @override
  void initState() {
    super.initState();
    _controller = VlcPlayerController.network(
      rtspUrl,
      autoPlay: true,
      hwAcc: HwAcc.auto, // Usa accelerazione hardware
      options: VlcPlayerOptions(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RTSP Camera Stream")),
      body: Center(
        child: VlcPlayer(
          controller: _controller,
          aspectRatio: 16 / 9,
          placeholder: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}