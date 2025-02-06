import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:screenshot/screenshot.dart';

class CameraGalleryWidget extends StatefulWidget {
  final List<Uint8List> initialImages; // Immagini iniziali per il tipo di analisi
  final double containerWidth; // Larghezza del contenitore
  final double galleryHeight; // Altezza della galleria
  final Function(List<Uint8List>) onImagesUpdated; // Callback per inviare le immagini aggiornate

  const CameraGalleryWidget({
    Key? key,
    this.initialImages = const [],
    this.containerWidth = double.infinity,
    this.galleryHeight = 100.0,
    required this.onImagesUpdated,
  }) : super(key: key);

  @override
  _CameraGalleryWidgetState createState() => _CameraGalleryWidgetState();
}

class _CameraGalleryWidgetState extends State<CameraGalleryWidget> {
  VlcPlayerController? _vlcController; // Controller del player VLC
  String _videoUrl = "rtsp://192.168.1.181:8554/live"; // URL di default (modificabile dal menu settings)
  final ScreenshotController _screenshotController = ScreenshotController(); // Controller per catturare screenshot
  List<Uint8List> _capturedImages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _capturedImages = List.from(widget.initialImages); // Imposta immagini iniziali
    _initializeVLCController(_videoUrl);
  }

  void _initializeVLCController(String url) {
    // Dispone del controller precedente, se esiste
    _vlcController?.dispose();
    _vlcController = VlcPlayerController.network(
      _videoUrl,
      autoPlay: true,
      hwAcc: HwAcc.auto, // 🔹 Usa AUTO invece di FULL per maggiore stabilità
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(300), // 🔹 Buffering migliorato per RTSP
          VlcAdvancedOptions.liveCaching(300),
        ]),
        extras: [
          '--rtsp-tcp', // 🔹 Forza RTSP su TCP per maggiore stabilità
          '--network-caching=300',
          '--no-stats',
          '--drop-late-frames',
          '--skip-frames',
        ],
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _vlcController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      // Utilizza il package "screenshot" per catturare l'immagine del widget video
      Uint8List? imageData = await _screenshotController.capture();
      if (imageData != null) {
        setState(() {
          _capturedImages.add(imageData);
        });
        // Invia le immagini aggiornate tramite il callback
        widget.onImagesUpdated(_capturedImages);
      }
    } catch (e) {
      print("Errore durante lo scatto della foto: $e");
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
    // Invia le immagini aggiornate tramite il callback
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

  void _openUrlInputDialog() {
    final TextEditingController urlController =
        TextEditingController(text: _videoUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Imposta URL RTSP'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              hintText: 'Inserisci l\'URL RTSP',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Chiude la dialog senza salvare
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _videoUrl = urlController.text;
                  _initializeVLCController(_videoUrl);
                });
                Navigator.pop(context);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenitore video con pulsante per scattare
          Container(
            width: widget.containerWidth,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: (_vlcController == null)
                  ? const Center(
                      child: CircularProgressIndicator(), // Rotella di caricamento
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Il widget VlcPlayer è racchiuso all'interno di Screenshot per consentire lo snapshot
                        Screenshot(
                          controller: _screenshotController,
                          child: VlcPlayer(
                            controller: _vlcController!,
                            aspectRatio: 16 / 9,
                            placeholder: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                        // Pulsante per scattare lo screenshot
                        Positioned(
                          bottom: 24,
                          child: GestureDetector(
                            onTap: _capturePhoto,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.black, size: 28),
                            ),
                          ),
                        ),
                        // Icona settings per impostare l'URL RTSP
                        Positioned(
                          top: 16,
                          right: 16,
                          child: GestureDetector(
                            onTap: _openUrlInputDialog,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
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
            ),
          ),
          const SizedBox(height: 12),
          // Contenitore galleria
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
                  ? const Center(
                      child: Text(
                        'Nessuna immagine catturata',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : Row(
                      children: [
                        IconButton(
                          onPressed: _scrollLeft,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: widget.galleryHeight,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              controller: _scrollController,
                              itemCount: _capturedImages.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          _capturedImages[index],
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _deleteImage(index),
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _scrollRight,
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
