import 'package:flutter/material.dart';

class ManualePage extends StatefulWidget {
  const ManualePage({Key? key}) : super(key: key);

  @override
  _ManualePageState createState() => _ManualePageState();
}

class _ManualePageState extends State<ManualePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Due tab: Operatore e Sviluppatore
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Manuale',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.grey.withOpacity(0.4),
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Manuale Operatore'),
              Tab(text: 'Manuale Sviluppatore'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Contenuto del Manuale Operatore (guida simulata)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Guida Operatore:\n\n'
                  '1. Accendere il dispositivo e attendere il caricamento completo.\n'
                  '2. Selezionare il paziente dalla lista.\n'
                  '3. Eseguire la procedura di analisi manuale seguendo le istruzioni visualizzate.\n'
                  '4. In caso di anomalie, contattare il responsabile tecnico.\n\n'
                  'Questa è una guida simulata per l\'operatore. Informazioni aggiuntive verranno aggiornate in futuro.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            // Contenuto del Manuale Sviluppatore (informazioni simulate)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Guida Sviluppatore:\n\n'
                  '1. Configurare l\'ambiente di sviluppo seguendo la documentazione tecnica ufficiale.\n'
                  '2. Utilizzare il package XYZ per l\'integrazione del 3D Model Viewer.\n'
                  '3. Assicurarsi che le API siano correttamente configurate con le credenziali fornite.\n'
                  '4. Eseguire i test unitari per verificare la funzionalità delle nuove feature.\n\n'
                  'Questa è una guida simulata per gli sviluppatori. Informazioni tecniche dettagliate saranno disponibili in una documentazione più completa.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
