import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';              // salvataggio temp 📁
import 'package:permission_handler/permission_handler.dart';    // gestione permessi 🛂
import 'package:uvccamera/uvccamera.dart';                      // plugin UVC 📷

/// ---------------------------------------------------------------------------
/// Camera + Gallery (Android) – stesso layout/feature della versione Web.
/// ---------------------------------------------------------------------------
/// * [_timerSeconds] regolabile da dialog ⚙️ (0 = scatto immediato).
/// * Countdown disegnato sul pulsante di scatto.
/// * Mini-galleria con frecce, elimino singola immagine, callback verso parent.
/// ---------------------------------------------------------------------------
class CameraGalleryMobileWidget extends StatefulWidget {
  final List<String> initialImages;           // base64 PNG
  final double containerWidth;
  final double galleryHeight;
  final Function(List<String>) onImagesUpdated;
  final int initialTimerSeconds;

  const CameraGalleryMobileWidget({
    Key? key,
    this.initialImages = const [],
    this.containerWidth = double.infinity,
    this.galleryHeight = 100.0,
    required this.onImagesUpdated,
    this.initialTimerSeconds = 5,
  }) : super(key: key);

  @override
  State<CameraGalleryMobileWidget> createState() =>
      _CameraGalleryMobileWidgetState();
}

class _CameraGalleryMobileWidgetState extends State<CameraGalleryMobileWidget> {
  //------------------------------------------------------------------
  // UVC CAMERA
  //------------------------------------------------------------------
  UvcCameraController? _ctl;
  bool _initializing = true;
  String _initError = '';
  late StreamSubscription<UvcCameraDeviceEvent> _deviceSub;
  //------------------------------------------------------------------
  // GALLERIA
  //------------------------------------------------------------------
  late List<String> _capturedImages;
  final ScrollController _scrollCtl = ScrollController();

  //------------------------------------------------------------------
  // AUTOSCATTO
  //------------------------------------------------------------------
  late int _timerSeconds;
  Timer? _countdownT;
  int? _countdownRemaining;

  //------------------------------------------------------------------
  // LIFECYCLE
  //------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _capturedImages = List<String>.from(widget.initialImages);
    _timerSeconds = widget.initialTimerSeconds;

  // ① ascolto detach per evitare crash nativo
    _deviceSub = UvcCamera.deviceEventStream.listen((event) {
      if (event.type == UvcCameraDeviceEventType.detached) {
        // smonto il controller e mostro stato di errore
        _disposeController();
        setState(() {
          _initializing = false;
          _initError = 'Webcam scollegata';
        });
      }
    });

    _openFirstCamera();
  }

  @override
  void dispose() {
    _deviceSub.cancel();  // ② stop ascolto eventi
    _countdownT?.cancel();
    _ctl?.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

void _disposeController() {
  if (_ctl != null) {
    try {
      _ctl!.dispose();    // chiude preview e risorse native
    } catch (_) {
      // ignoro eventuali errori di dispose su controller già smontato
    }
    _ctl = null;
  }
}

  void _refreshConnection() {
    // se c’è già un controller, lo chiudiamo
    _ctl?.dispose();
    // ricominciamo l’inizializzazione
    _openFirstCamera();
  }
  //------------------------------------------------------------------
  // CAMERA INIT
  //------------------------------------------------------------------
  Future<void> _openFirstCamera() async {
    setState(() {
      _initializing = true;
      _initError = '';
    });

    // 1️⃣ permesso CAMERA
    if (!(await Permission.camera.request()).isGranted) {
      setState(() {
        _initializing = false;
        _initError = 'Permesso CAMERA negato';
      });
      return;
    }

    // 2️⃣ enumerazione device UVC
    final devices = await UvcCamera.getDevices();             // :contentReference[oaicite:0]{index=0}
    if (devices.isEmpty) {
      setState(() {
        _initializing = false;
        _initError = 'Nessuna webcam USB rilevata';
      });
      return;
    }
    final device = devices.values.first;

    // 3️⃣ permesso USB
    if (!await UvcCamera.requestDevicePermission(device)) {   // :contentReference[oaicite:1]{index=1}
      setState(() {
        _initializing = false;
        _initError = 'Permesso USB negato';
      });
      return;
    }

    // 4️⃣ controller
    final c = UvcCameraController(device: device);
    try {
      await c.initialize();
      setState(() {
        _ctl = c;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _initializing = false;
        _initError = 'Errore init webcam:\n$e';
      });
    }
  }

  //------------------------------------------------------------------
  // CAPTURE
  //------------------------------------------------------------------
  Future<void> _onCapturePressed() async {
    if (_countdownRemaining != null || _ctl == null) return;
    if (_timerSeconds == 0) {
      _takeShot();
    } else {
      _startCountdown();
    }
  }

  void _startCountdown() {
    setState(() => _countdownRemaining = _timerSeconds);
    _countdownT = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_countdownRemaining! > 1) {
          _countdownRemaining = _countdownRemaining! - 1;
        } else {
          t.cancel();
          _countdownRemaining = null;
          _takeShot();
        }
      });
    });
  }

  Future<void> _takeShot() async {
    if (!(_ctl?.value.isInitialized ?? false)) return;
    try {
      final file = await _ctl!.takePicture();                 // API ≥0.0.12 :contentReference[oaicite:2]{index=2}
      final bytes = await File(file.path).readAsBytes();
      final b64 = 'data:image/png;base64,${base64.encode(bytes)}';
      setState(() => _capturedImages.add(b64));
      widget.onImagesUpdated(_capturedImages);
    } catch (e) {
      debugPrint('Errore scatto: $e');
    }
  }

  //------------------------------------------------------------------
  // SETTINGS
  //------------------------------------------------------------------
  void _openSettings() {
    final timerCtl = TextEditingController(text: _timerSeconds.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Impostazioni'),
        content: TextField(
          controller: timerCtl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Autoscatto (s)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(timerCtl.text);
              if (v != null && v >= 0) {
                setState(() => _timerSeconds = v);
              }
              Navigator.pop(context);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  //------------------------------------------------------------------
  // SCROLL GALLERY
  //------------------------------------------------------------------
  void _scrollLeft() => _scrollCtl.animateTo(
        _scrollCtl.offset - 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );                                                       // :contentReference[oaicite:3]{index=3}

  void _scrollRight() => _scrollCtl.animateTo(
        _scrollCtl.offset + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );                                                       // :contentReference[oaicite:4]{index=4}

  //------------------------------------------------------------------
  // UI
  //------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //-------------------------------------------------- PREVIEW
        SizedBox(
          width: widget.containerWidth,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_initializing)
                  const Center(child: CircularProgressIndicator())
                else if (_initError.isNotEmpty)
                  Center(child: Text(_initError, textAlign: TextAlign.center))
                else
                  UvcCameraPreview(_ctl!),                       // widget ufficiale :contentReference[oaicite:5]{index=5}

                // ➜ pulsante scatto / countdown
                Positioned(
                  bottom: 24,
                  child: GestureDetector(
                    onTap: _onCapturePressed,
                    child: _buildCaptureButton(),
                  ),
                ),
                // ➜ PULSANTE REFRESH (NUOVO)
                Positioned(
                  top: 16,
                  right: 64,           // spostato a sinistra di 48px dal settings
                  child: GestureDetector(
                    onTap: _refreshConnection,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.refresh, color: Colors.black),
                    ),
                  ),
                ),
                // ➜ icona impostazioni
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _openSettings,
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
        //-------------------------------------------------- GALLERY
        Container(
          width: widget.containerWidth,
          height: widget.galleryHeight,
          padding: const EdgeInsets.symmetric(vertical: 8),
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
              ? const Center(
                  child: Text('Nessuna immagine catturata',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                )
              : Row(
                  children: [
                    IconButton(
                        onPressed: _scrollLeft,
                        icon: const Icon(Icons.arrow_back)),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtl,
                        scrollDirection: Axis.horizontal,
                        itemCount: _capturedImages.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Stack(
                            children: [
                              Image.memory(
                                base64Decode(
                                    _capturedImages[i].split(',').last),
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _capturedImages.removeAt(i));
                                      widget
                                          .onImagesUpdated(_capturedImages);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 16, color: Colors.white),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: _scrollRight,
                        icon: const Icon(Icons.arrow_forward)),
                  ],
                ),
        ),
      ],
    );
  }

  //------------------------------------------------------------------
  // PULSANTE SCATTO
  //------------------------------------------------------------------
  Widget _buildCaptureButton() {
    if (_countdownRemaining != null) {
      return Container(
        width: 60,
        height: 60,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          _countdownRemaining.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.camera_alt, color: Colors.black, size: 28),
    );
  }
}
