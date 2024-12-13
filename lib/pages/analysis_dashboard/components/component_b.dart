import 'package:flutter/material.dart';

class ComponentB extends StatelessWidget {
  final int score;
  final String description;
  final String professionalEvaluation;
  final String advice;

  const ComponentB({
    Key? key,
    required this.score,
    required this.description,
    required this.professionalEvaluation,
    required this.advice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0), // Outer padding for the entire component
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0), // Inner padding for content
          decoration: BoxDecoration(
            color: Colors.white, // Background color
            borderRadius: BorderRadius.circular(2), // Match other components' radius
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Section
              Column(
                children: [
                  Text(
                    (score/100).toString(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getColorForScore(score), // Dynamic color based on score
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Anomalo", style: TextStyle(fontSize: 12, color: Colors.red)),
                      Text("Nella norma", style: TextStyle(fontSize: 12, color: Colors.green)),
                    ],
                  ),
                  Slider(
                    value: score.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    onChanged: null,
                    activeColor: _getColorForScore(score), // Dynamic slider color
                    inactiveColor: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description Section
              _buildSection(
                title: "Descrizione",
                content: description,
              ),
              const SizedBox(height: 16),
              // Professional Evaluation Section
              _buildSection(
                title: "Valutazione Professionale",
                content: professionalEvaluation,
              ),
              const SizedBox(height: 16),
              // Advice Section
              _buildSection(
                title: "Consigli",
                content: advice,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Determine the color based on the score value
  Color _getColorForScore(int score) {
    if (score <= 40) {
      return Colors.red;
    } else if (score > 40 && score < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
