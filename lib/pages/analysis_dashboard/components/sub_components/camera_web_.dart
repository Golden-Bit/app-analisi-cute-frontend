import 'dart:html' as html;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CameraGalleryWebWidget extends StatefulWidget {
  final List<String> initialImages; // Immagini in Base64
  final double containerWidth; // Larghezza del contenitore
  final double galleryHeight; // Altezza della galleria
  final Function(List<String>) onImagesUpdated; // Callback per aggiornare le immagini

  const CameraGalleryWebWidget({
    Key? key,
    this.initialImages = const [],
    this.containerWidth = double.infinity,
    this.galleryHeight = 100.0,
    required this.onImagesUpdated,
  }) : super(key: key);

  @override
  _CameraGalleryWebWidgetState createState() => _CameraGalleryWebWidgetState();
}

class _CameraGalleryWebWidgetState extends State<CameraGalleryWebWidget> {
  //String _videoUrl = "http://evnq5soayg5gt.local:8081/video";
  String _videoUrl = "http://127.0.0.1:8081/video";
  List<String> _capturedImages = []; // Lista immagini in Base64
  final ScrollController _scrollController = ScrollController();

  late html.ImageElement _mjpegImage;
  late html.CanvasElement _canvas;
  late html.CanvasRenderingContext2D _ctx;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _capturedImages = List.from(widget.initialImages);
    _setupMjpegStream();
  }

  /// Configura lo stream MJPEG
  void _setupMjpegStream() {
    print("🔍 Creazione dello stream con URL: $_videoUrl");

    _mjpegImage = html.ImageElement()
      ..src = _videoUrl
      ..style.width = "100%"
      ..style.height = "auto"
      ..crossOrigin = "anonymous";

    _mjpegImage.onLoad.listen((event) {
      print("✅ Stream caricato con successo!");
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    });

    _mjpegImage.onError.listen((event) {
      print("❌ Errore nel caricamento dello stream MJPEG!");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    });

    if (kIsWeb) {
      ui.platformViewRegistry.registerViewFactory(
        'mjpeg-stream-view',
        (int viewId) => _mjpegImage,
      );
    }

    _canvas = html.CanvasElement();
    _ctx = _canvas.context2D;
  }

  /// Cambia l'URL dello stream MJPEG
  void _openUrlInputDialog() {
    final TextEditingController urlController =
        TextEditingController(text: _videoUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Imposta URL dello stream MJPEG'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              hintText: 'Inserisci l\'URL (es: http://IP:8081/video)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (urlController.text.isNotEmpty) {
                    _videoUrl = urlController.text;
                    _setupMjpegStream();
                  }
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

  /// Cattura immagine dello stream MJPEG
  void _capturePhoto() async {
    if (_mjpegImage.complete == false) {
      print("⚠️ L'immagine non è ancora completamente caricata.");
      return;
    }

    try {
      _canvas.width = _mjpegImage.width;
      _canvas.height = _mjpegImage.height;
      _ctx.drawImage(_mjpegImage, 0, 0);

      String base64Image = _canvas.toDataUrl("image/png");
      setState(() {
        _capturedImages.add(base64Image);
      });

      widget.onImagesUpdated(_capturedImages);
      print("📸 Foto catturata con successo!");
    } catch (e) {
      print("❌ Errore durante lo screenshot: $e");
    }
  }

  /// Elimina immagine dalla galleria
  void _deleteImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
    widget.onImagesUpdated(_capturedImages);
  }

  /// Scorri la galleria a sinistra
  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 120,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Scorri la galleria a destra
  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 120,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Contenitore video sopra
        Container(
          width: widget.containerWidth,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _isLoading
                    ? const CircularProgressIndicator()
                    : _hasError
                        ? const Text("Errore nel caricamento dello stream MJPEG")
                        : HtmlElementView(viewType: 'mjpeg-stream-view'),
                // Pulsante screenshot
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
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 28),
                    ),
                  ),
                ),
                // Icona settings per cambiare URL
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
                      child: const Icon(Icons.settings, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Galleria immagini sotto
        Container(
          width: widget.containerWidth,
          height: widget.galleryHeight,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          child: _capturedImages.isEmpty
              ? const Center(child: Text('Nessuna immagine catturata', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : Row(
                  children: [
                    IconButton(
                      onPressed: _scrollLeft, 
                      icon: const Icon(Icons.arrow_back)
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        controller: _scrollController,
                        itemCount: _capturedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Stack(
                              children: [
                                // L'immagine occupa tutta l'altezza della galleria
                                Image.network(
                                  _capturedImages[index],
                                  width: 100,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                // Icona 'X' per eliminare l'immagine, posizionata in alto a destra
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _deleteImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: _scrollRight, 
                      icon: const Icon(Icons.arrow_forward)
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
