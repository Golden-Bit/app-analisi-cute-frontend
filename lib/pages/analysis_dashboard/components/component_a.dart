// Componente A
import 'package:flutter/material.dart';

class ComponentA extends StatefulWidget {
  final double heightFactor;
  final double borderRadius;
  final Function(String) onAnalysisSelected; // Callback per notificare la selezione

  const ComponentA({
    Key? key,
    required this.heightFactor,
    required this.borderRadius,
    required this.onAnalysisSelected, // Callback
  }) : super(key: key);

  @override
  _ComponentAState createState() => _ComponentAState();
}

class _ComponentAState extends State<ComponentA> {
  final List<String> titles = [
    "Idratazione",
    "Strato lipidico",
    "Elasticità",
    "Cheratina",
    "Pelle sensibile",
    "Macchie cutanee",
    "Tonalità",
    "Densità pilifera",
    "Pori ostruiti",
  ];
  int selectedIndex = 0; // Prima scheda selezionata di default

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: titles.length,
        itemBuilder: (context, index) {
          final bool isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index; // Aggiorna la selezione
              });
              widget.onAnalysisSelected(titles[index]); // Notifica la selezione
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                color: isSelected ? Colors.black : Colors.white,
                border: Border.all(color: Colors.black),
              ),
              height: MediaQuery.of(context).size.height * widget.heightFactor * 0.2,
              child: Center(
                child: Text(
                  titles[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}