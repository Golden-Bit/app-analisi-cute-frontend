import 'package:flutter/material.dart';
import 'package:app_analisi_cute/pages/anagraphic_cards/components/anagraphic_card_viewer.dart';
import 'package:app_analisi_cute/backend_sdk/patients.dart';

class HoverableCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Anagrafica anagrafica; // Oggetto completo dell'anagrafica

  const HoverableCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.anagrafica,
  }) : super(key: key);

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2), // Imposta il border radius a 2
        ),
        child: ListTile(
          title: Text(widget.title),
          subtitle: Text(widget.subtitle),
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz,
              color: _isHovered ? Colors.black : Colors.grey[300],
            ),
            onSelected: (String value) {
              if (value == 'Visualizza') {
                showDialog(
                  context: context,
                  builder: (context) => AnagraficaView(anagrafica: widget.anagrafica),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Visualizza',
                child: Text('Visualizza'),
              ),
              const PopupMenuItem<String>(
                value: 'Modifica',
                child: Text('Modifica'),
              ),
              const PopupMenuItem<String>(
                value: 'Elimina',
                child: Text('Elimina'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
