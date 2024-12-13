import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ThreeDModelViewer extends StatelessWidget {
  final String src; // Percorso del file 3D
  final String alt; // Testo alternativo per accessibilità
  final bool autoRotate; // Abilita rotazione automatica
  final bool cameraControls; // Abilita controlli della camera

  const ThreeDModelViewer({
    Key? key,
    required this.src,
    this.alt = 'Modello 3D',
    this.autoRotate = false,
    this.cameraControls = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: src,
      alt: alt,
      autoRotate: autoRotate,
      cameraControls: cameraControls,
    );
  }
}
