import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ThreeDModelViewer extends StatelessWidget {
  final String modelUrl; // URL del file 3D
  final bool autoRotate;
  final bool cameraControls;

  const ThreeDModelViewer({
    Key? key,
    required this.modelUrl,
    this.autoRotate = false,
    this.cameraControls = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
          src: modelUrl,
          alt: "Modello 3D",
          ar: true, // Abilita AR su dispositivi compatibili
          autoRotate: autoRotate, // Abilita/disabilita rotazione
          cameraControls: cameraControls, // Abilita controlli fotocamera
          disableZoom: !cameraControls, // Permetti zoom se abilitato
        );
    }
}
