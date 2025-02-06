import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  MediaStream? _stream;
  List<MediaDeviceInfo> _availableCameras = [];
  MediaDeviceInfo? _selectedCamera;
  List<Uint8List> _capturedImages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeCameraSystem();
    _capturedImages = List.from(widget.initialImages);
  }

/// Ottiene la lista di TUTTI i dispositivi (non solo le telecamere)
Future<void> _initializeCameraSystem() async {
  await _renderer.initialize();

  List<MediaDeviceInfo> devices =
      await navigator.mediaDevices.enumerateDevices();
  
  // 🔹 Ora raccogliamo TUTTI i dispositivi (non solo "videoinput")
  _availableCameras = devices; 

  if (_availableCameras.isNotEmpty) {
    setState(() {
      _selectedCamera = _availableCameras.first;
    });
    await _initializeCamera(_selectedCamera!);
  } else {
    print("❌ Nessun dispositivo trovato.");
  }
}


  /// Inizializza la telecamera selezionata
  Future<void> _initializeCamera(MediaDeviceInfo camera) async {
    _stream?.getTracks().forEach((track) => track.stop());

    var constraints = {
      "video": {
        "deviceId": camera.deviceId,
        "width": 1280,
        "height": 720,
      },
      "audio": false,
    };

    _stream = await navigator.mediaDevices.getUserMedia(constraints);
    _renderer.srcObject = _stream;

    setState(() {});
  }

  @override
  void dispose() {
    _renderer.dispose();
    _scrollController.dispose();
    _stream?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

  /// Cattura una foto dalla telecamera
  Future<void> _capturePhoto() async {
    try {
      if (_renderer.srcObject == null) return;

      final videoTrack = _stream?.getVideoTracks().first;
      if (videoTrack == null) return;

      final ByteBuffer frameBuffer = await videoTrack.captureFrame();
      final Uint8List frame = frameBuffer.asUint8List(); // 🔹 Conversione corretta

      setState(() {
        _capturedImages.add(frame);
      });

      widget.onImagesUpdated(_capturedImages);
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

  /// Mostra un menu popup con le telecamere disponibili
  void _showCameraSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Seleziona una telecamera"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _availableCameras.map((camera) {
              return ListTile(
                title: Text(camera.label.isNotEmpty ? camera.label : "Camera Sconosciuta"),
                onTap: () {
                  Navigator.of(context).pop();
                  _initializeCamera(camera);
                },
              );
            }).toList(),
          ),
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
          Stack(
            alignment: Alignment.topRight,
            children: [
              // Anteprima della telecamera
              Container(
                width: widget.containerWidth,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _stream == null
                      ? const Center(child: CircularProgressIndicator())
                      : RTCVideoView(_renderer),
                ),
              ),
              // Pulsante impostazioni (rotella) in alto a destra
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _showCameraSelectionDialog,
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _capturedImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
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
