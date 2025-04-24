import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Camera + Gallery (Web) con supporto autoscatto regolabile.
/// -----------------------------------------------------------
/// * [_timerSeconds] è modificabile runtime tramite dialog ⚙️.
/// * Se 0 ⇒ scatto immediato; se >0 ⇒ conto alla rovescia.
/// * Durante il countdown il pulsante di scatto mostra il numero.
/// -----------------------------------------------------------
class CameraGalleryWebWidget extends StatefulWidget {
  /// Immagini iniziali (in Base64) – una per zona.
  final List<String> initialImages;

  /// Larghezza del contenitore video/galleria.
  final double containerWidth;

  /// Altezza della galleria.
  final double galleryHeight;

  /// Callback per comunicare le immagini catturate al parent.
  final Function(List<String>) onImagesUpdated;

  /// Valore di autoscatto iniziale (secondi, 0 = disattivato). Default 5.
  final int initialTimerSeconds;

  const CameraGalleryWebWidget({
    Key? key,
    this.initialImages = const [],
    this.containerWidth = double.infinity,
    this.galleryHeight = 100.0,
    required this.onImagesUpdated,
    this.initialTimerSeconds = 5,
  }) : super(key: key);

  @override
  State<CameraGalleryWebWidget> createState() => _CameraGalleryWebWidgetState();
}

class _CameraGalleryWebWidgetState extends State<CameraGalleryWebWidget> {
  //------------------------------------------------------------------
  // STREAM & CANVAS
  //------------------------------------------------------------------
  String _videoUrl = 'http://127.0.0.1:8081/video';
  late html.ImageElement _mjpegImage;
  late html.CanvasElement _canvas;
  late html.CanvasRenderingContext2D _ctx;

  //------------------------------------------------------------------
  // GALLERIA
  //------------------------------------------------------------------
  List<String> _capturedImages = [];
  final ScrollController _scrollController = ScrollController();

  //------------------------------------------------------------------
  // STATE GENERICO
  //------------------------------------------------------------------
  bool _isLoading = true;
  bool _hasError = false;

  //------------------------------------------------------------------
  // AUTOSCATTO
  //------------------------------------------------------------------
  late int _timerSeconds; // <-- modificabile runtime
  Timer? _countdownTimer;
  int? _countdownRemaining; // null = nessun countdown attivo

  //------------------------------------------------------------------
  // LIFECYCLE
  //------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _capturedImages = List<String>.from(widget.initialImages);
    _timerSeconds = widget.initialTimerSeconds;
    _setupMjpegStream();
  }

  @override
  void didUpdateWidget(covariant CameraGalleryWebWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImages != widget.initialImages) {
      setState(() => _capturedImages = List<String>.from(widget.initialImages));
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  //------------------------------------------------------------------
  // STREAM SETUP
  //------------------------------------------------------------------
  void _setupMjpegStream() {
    _mjpegImage = html.ImageElement()
      ..src = _videoUrl
      ..style.width = '100%'
      ..style.height = 'auto'
      ..crossOrigin = 'anonymous';

    _mjpegImage.onLoad.first.then((_) => setState(() {
          _isLoading = false;
          _hasError = false;
        }));

    _mjpegImage.onError.first.then((_) => setState(() {
          _isLoading = false;
          _hasError = true;
        }));

    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory('mjpeg-stream-view', (_) => _mjpegImage);
    }

    _canvas = html.CanvasElement();
    _ctx = _canvas.context2D;
  }

  //------------------------------------------------------------------
  // SETTINGS DIALOG
  //------------------------------------------------------------------
  void _openSettingsDialog() {
    final urlCtl = TextEditingController(text: _videoUrl);
    final timerCtl = TextEditingController(text: _timerSeconds.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Impostazioni'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtl,
              decoration: const InputDecoration(labelText: 'URL stream MJPEG'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timerCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Autoscatto (s)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              setState(() {
                if (urlCtl.text.isNotEmpty && urlCtl.text != _videoUrl) {
                  _videoUrl = urlCtl.text;
                  _setupMjpegStream();
                }
                final parsed = int.tryParse(timerCtl.text);
                if (parsed != null && parsed >= 0) _timerSeconds = parsed;
              });
              Navigator.pop(context);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  //------------------------------------------------------------------
  // CAPTURE LOGIC
  //------------------------------------------------------------------
  void _onCapturePressed() {
    if (_countdownRemaining != null) return; // countdown già in corso
    if (_timerSeconds == 0) {
      _capturePhoto();
    } else {
      _startCountdown();
    }
  }

  void _startCountdown() {
    setState(() => _countdownRemaining = _timerSeconds);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_countdownRemaining! > 1) {
          _countdownRemaining = _countdownRemaining! - 1;
        } else {
          t.cancel();
          _countdownRemaining = null;
          _capturePhoto();
        }
      });
    });
  }

  void _capturePhoto() {
    if (!(_mjpegImage.complete ?? false)) return;

    try {
      _canvas.width = _mjpegImage.width;
      _canvas.height = _mjpegImage.height;
      _ctx.drawImage(_mjpegImage, 0, 0);
      final base64 = _canvas.toDataUrl('image/png');
      setState(() => _capturedImages.add(base64));
      widget.onImagesUpdated(_capturedImages);
    } catch (e) {
      debugPrint('Errore cattura foto: $e');
    }
  }

  //------------------------------------------------------------------
  // UI AUX
  //------------------------------------------------------------------
  void _deleteImage(int index) {
    setState(() => _capturedImages.removeAt(index));
    widget.onImagesUpdated(_capturedImages);
  }

  void _scrollLeft() => _scrollController.animateTo(
        _scrollController.offset - 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

  void _scrollRight() => _scrollController.animateTo(
        _scrollController.offset + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

  //------------------------------------------------------------------
  // BUILD
  //------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //------------------------------------------------------
        // VIDEO STREAM
        //------------------------------------------------------
        SizedBox(
          width: widget.containerWidth,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _isLoading
                    ? const CircularProgressIndicator()
                    : _hasError
                        ? const Text('Errore stream MJPEG')
                        : HtmlElementView(viewType: 'mjpeg-stream-view'),

                // ➜ Pulsante scatto / countdown
                Positioned(
                  bottom: 24,
                  child: GestureDetector(
                    onTap: _onCapturePressed,
                    child: _buildCaptureButton(),
                  ),
                ),

                // ➜ Icona impostazioni
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _openSettingsDialog,
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
        //------------------------------------------------------
        // GALLERIA
        //------------------------------------------------------
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
                    IconButton(onPressed: _scrollLeft, icon: const Icon(Icons.arrow_back)),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        controller: _scrollController,
                        itemCount: _capturedImages.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Stack(
                            children: [
                              Image.network(_capturedImages[i], width: 100, fit: BoxFit.cover),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _deleteImage(i),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(onPressed: _scrollRight, icon: const Icon(Icons.arrow_forward)),
                  ],
                ),
        ),
      ],
    );
  }

  //------------------------------------------------------------------
  // WIDGET PULSANTE / COUNTDOWN
  //------------------------------------------------------------------
  Widget _buildCaptureButton() {
    if (_countdownRemaining != null) {
      return Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
