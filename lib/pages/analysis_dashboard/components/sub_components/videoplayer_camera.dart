import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:video_player/video_player.dart';

class WebRtcCameraGalleryWidget extends StatefulWidget {
  final List<Uint8List> initialImages;
  final double containerWidth;
  final double galleryHeight;
  final Function(List<Uint8List>) onImagesUpdated;

  const WebRtcCameraGalleryWidget({
    Key? key,
    this.initialImages = const [],
    this.containerWidth = double.infinity,
    this.galleryHeight = 100.0,
    required this.onImagesUpdated,
  }) : super(key: key);

  @override
  _WebRtcCameraGalleryWidgetState createState() =>
      _WebRtcCameraGalleryWidgetState();
}

class _WebRtcCameraGalleryWidgetState extends State<WebRtcCameraGalleryWidget> {
  late VideoPlayerController _videoController;
  final TextEditingController _ipController =
      TextEditingController(text: "http://192.168.1.181:8081"); // Default IP
  List<Uint8List> _capturedImages = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _videoKey = GlobalKey(); // Chiave per acquisire il video

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _capturedImages = List.from(widget.initialImages);
  }

  /// Inizializza il video player con l'IP attuale
  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.network(_ipController.text)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
      }).catchError((error) {
        print("❌ Errore caricamento video: $error");
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _scrollController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  /// Aggiorna l'IP della telecamera e ricarica il video
  void _updateCameraIP() {
    setState(() {
      _videoController.dispose();
      _initializeVideoPlayer();
    });
  }

  /// Mostra un dialog per cambiare l'IP della telecamera
  void _showIPSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Imposta IP della Telecamera"),
          content: TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: "Inserisci l'URL della telecamera",
              hintText: "http://192.168.1.181:8081",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateCameraIP();
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  /// Cattura un frame dal video usando `RepaintBoundary`
  Future<void> _capturePhoto() async {
    try {
      RenderRepaintBoundary boundary = _videoKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Uint8List frame = byteData.buffer.asUint8List();
        setState(() {
          _capturedImages.add(frame);
        });
        widget.onImagesUpdated(_capturedImages);
      }
    } catch (e) {
      print("❌ Errore durante lo scatto della foto: $e");
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });

    widget.onImagesUpdated(_capturedImages);
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 120,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 120,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              // Anteprima del video con `RepaintBoundary`
              RepaintBoundary(
                key: _videoKey, // Chiave per acquisire il frame
                child: Container(
                  width: widget.containerWidth,
                  child: AspectRatio(
                    aspectRatio: _videoController.value.isInitialized
                        ? _videoController.value.aspectRatio
                        : 16 / 9,
                    child: _videoController.value.isInitialized
                        ? VideoPlayer(_videoController)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              // Pulsante impostazioni (rotella) per impostare l'IP
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _showIPSettingsDialog,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pulsante per scattare foto
          GestureDetector(
            onTap: _capturePhoto,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.black, size: 28),
            ),
          ),
          const SizedBox(height: 12),

          // Galleria immagini
          Container(
            width: widget.containerWidth,
            height: widget.galleryHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(0, 2),
                  blurRadius: 2,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
              child: _capturedImages.isEmpty
                  ? const Center(child: Text('Nessuna immagine catturata'))
                  : Row(
                      children: [
                        IconButton(onPressed: _scrollLeft, icon: const Icon(Icons.arrow_back)),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            controller: _scrollController,
                            itemCount: _capturedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Image.memory(
                                  _capturedImages[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                        IconButton(onPressed: _scrollRight, icon: const Icon(Icons.arrow_forward)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
