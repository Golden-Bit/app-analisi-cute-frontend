import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ThreeDModelViewer extends StatelessWidget {
  final String modelUrl;           // URL del file 3D
  final bool autoRotate;           // Abilita/disabilita rotazione automatica
  final bool cameraControls;       // Abilita/disabilita i controlli della telecamera

  // Parametri opzionali per controllare la telecamera e l'aspetto
  final int? autoRotateDelay;      // Ritardo (in millisecondi) prima di avviare l'auto-rotazione
  final String? cameraOrbit;       // Specifica l'orbita iniziale della telecamera (es. "45deg 75deg 2.5m")
  final String? cameraTarget;      // Specifica il punto centrale verso cui la telecamera è orientata (es. "0m 0m 0m")
  final String? fieldOfView;       // Campo visivo (es. "45deg")
  final String? environmentImage;  // URL di un'immagine ambientale per illuminazione/ambiente
  final double? exposure;          // Esposizione (es. 1.0)
  final double? shadowIntensity;   // Intensità dell'ombra (es. 0.5)
  final Color? backgroundColor;   // Colore di sfondo (es. "#ffffff")

  const ThreeDModelViewer({
    Key? key,
    required this.modelUrl,
    this.autoRotate = false,
    this.cameraControls = true,
    this.autoRotateDelay,
    this.cameraOrbit,
    this.cameraTarget,
    this.fieldOfView,
    this.environmentImage,
    this.exposure,
    this.shadowIntensity,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: modelUrl,
      alt: "Modello 3D",
      ar: true,                      // Abilita AR su dispositivi compatibili
      autoRotate: autoRotate,        // Attiva la rotazione automatica
      cameraControls: cameraControls, // Abilita i controlli della telecamera
      disableZoom: !cameraControls,  // Disabilita lo zoom se i controlli non sono attivi
      // Passaggio dei parametri opzionali (se valorizzati)
      autoRotateDelay: autoRotateDelay,
      cameraOrbit: cameraOrbit,
      cameraTarget: cameraTarget,
      fieldOfView: fieldOfView,
      environmentImage: environmentImage,
      exposure: exposure,
      shadowIntensity: shadowIntensity,
      backgroundColor: backgroundColor ?? Colors.white,
    );
  }
}
