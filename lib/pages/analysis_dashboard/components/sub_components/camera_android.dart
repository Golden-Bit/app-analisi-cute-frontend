import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

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
  /// URL di default (puoi modificarlo se desideri un differente endpoint).
  /// Lo script MJPEG di default (secondo esempio) è su: `http://192.168.1.181:8081/video`.
  /// Aggiungiamo il parametro `t` per evitare eventuali cache sullo stream.
  String _videoUrl =
      "http://192.168.1.181:8081/video";

  final ScreenshotController _screenshotController = ScreenshotController(); // Controller per catturare screenshot
  List<Uint8List> _capturedImages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _capturedImages = List.from(widget.initialImages); // Imposta immagini iniziali
  }

  /// Apre un dialog che permette di cambiare l'URL dello stream MJPEG
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
              onPressed: () {
                Navigator.pop(context); // Chiude la dialog senza salvare
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  /// Se l'utente inserisce un URL, lo usiamo.
                  /// Altrimenti, lasciamo quello di default.
                  if (urlController.text.isNotEmpty) {
                    _videoUrl = urlController.text;
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

  /// Cattura la foto del widget corrente (in questo caso lo stream MJPEG)
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

  /// Elimina un'immagine dalla galleria
  void _deleteImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
    // Invia le immagini aggiornate tramite il callback
    widget.onImagesUpdated(_capturedImages);
  }

  /// Scorri la lista di immagini a sinistra
  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 120,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Scorri la lista di immagini a destra
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
          // Contenitore video con pulsante per scattare
          Container(
            width: widget.containerWidth,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Il widget Mjpeg è racchiuso all'interno di Screenshot
                  // per consentire lo snapshot
                  Screenshot(
                    controller: _screenshotController,
                    child: Mjpeg(
                      stream: _videoUrl,
                      // Imposta a true se vuoi segnalare che è uno stream in diretta
                      isLive: true,
                      // Se vuoi, puoi regolare frameRate e altri parametri
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
                  // Icona settings per impostare l'URL MJPEG
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
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
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
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8.0),
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
