import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
  CameraController? _controller; // Reso nullable per gestire correttamente lo stato iniziale
  Future<void>? _initializeControllerFuture;
  List<Uint8List> _capturedImages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _capturedImages = List.from(widget.initialImages); // Imposta immagini iniziali
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("Nessuna fotocamera disponibile.");
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture; // Assicura che il controller venga inizializzato
      setState(() {}); // Aggiorna lo stato per notificare l'inizializzazione
    } catch (e) {
      print("Errore durante l'inizializzazione della fotocamera: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Gestione sicura del nullable
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      if (_controller == null) return; // Evita di chiamare se il controller è null
      await _initializeControllerFuture;

      final XFile imageFile = await _controller!.takePicture();
      final Uint8List imageData = await imageFile.readAsBytes();

      setState(() {
        _capturedImages.add(imageData);
      });

      // Invia le immagini aggiornate tramite il callback
      widget.onImagesUpdated(_capturedImages);
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
              child: (_controller == null || _initializeControllerFuture == null)
                  ? const Center(
                      child: CircularProgressIndicator(), // Rotella di caricamento
                    )
                  : FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.connectionState == ConnectionState.done &&
                            _controller != null &&
                            _controller!.value.isInitialized) {
                          return Center(
                            child: AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: CameraPreview(_controller!),
                                  ),
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
                                ],
                              ),
                            ),
                          );
                        } else {
                          return const Center(
                            child: Text(
                              'Errore: impossibile caricare la fotocamera',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }
                      },
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
