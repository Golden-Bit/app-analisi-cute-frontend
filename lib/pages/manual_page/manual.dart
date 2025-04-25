import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pagina "Manuale" con due tab e quattro video nel primo tab.
/// Quando l'utente clicca sul pulsante ► accanto al video
/// viene aperto direttamente l'URL del file MP4 nel browser
/// (nuova scheda su Web, app esterna su mobile/desktop a seconda
/// della piattaforma).
class ManualePage extends StatefulWidget {
  const ManualePage({Key? key}) : super(key: key);

  @override
  State<ManualePage> createState() => _ManualePageState();
}

class _ManualePageState extends State<ManualePage> {
  late final List<_VideoItem> _videoItems;

  @override
  void initState() {
    super.initState();

    _videoItems = [
      _VideoItem(
        title: 'Intro e login',
        url:
            'https://video.wixstatic.com/video/63b1fb_0265e3ac82174341aeb85674fe7ac09b/1080p/mp4/file.mp4',
        description:
            'Come effettuare il login e panoramica iniziale dell’interfaccia.',
      ),
      _VideoItem(
        title: 'Connessione manipolo',
        url:
            'https://video.wixstatic.com/video/63b1fb_3ccf007e48ef458992cc716fda967a29/1080p/mp4/file.mp4',
        description: 'Collegare correttamente il manipolo al dispositivo.',
      ),
      _VideoItem(
        title: 'Anagrafiche',
        url:
            'https://video.wixstatic.com/video/63b1fb_195226fd7e0c4ff0aba0eb1e65060bd8/1080p/mp4/file.mp4',
        description: 'Creazione, modifica e gestione delle anagrafiche paziente.',
      ),
      _VideoItem(
        title: 'Analisi singola',
        url:
            'https://video.wixstatic.com/video/63b1fb_5ebbb919e7114c6cb405270bdb67fd4b/1080p/mp4/file.mp4',
        description:
            'Esecuzione di un’analisi singola con interpretazione dei risultati.',
      ),
    ];

    // Inizializza i VideoPlayerController per avere l'anteprima della clip.
    for (final item in _videoItems) {
      item.controller = VideoPlayerController.network(item.url)
        ..setLooping(true)
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    for (final item in _videoItems) {
      item.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Manuale', style: TextStyle(color: Colors.black)),
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
            _buildOperatoreTab(),
            _buildSviluppatoreTab(),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────── TAB 1 ────────────────────────────
  Widget _buildOperatoreTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemCount: _videoItems.length,
      itemBuilder: (_, index) => _VideoCard(item: _videoItems[index]),
    );
  }

  // ──────────────────────────── TAB 2 ────────────────────────────
  Widget _buildSviluppatoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
    );
  }
}

// ═══════════════════ MODELLI ═══════════════════
class _VideoItem {
  final String title;
  final String url;
  final String description;
  late final VideoPlayerController controller;

  _VideoItem({
    required this.title,
    required this.url,
    required this.description,
  });
}

// ═══════════════════ WIDGET LIST ITEM ═══════════════════
class _VideoCard extends StatelessWidget {
  final _VideoItem item;
  const _VideoCard({Key? key, required this.item}) : super(key: key);

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // su Web apre nuova scheda
      webOnlyWindowName: '_blank',
    )) {
      // Se non è possibile aprire l'URL, mostra un semplice snackbar.
      // In un progetto reale si gestirebbe diversamente.
      // ignore: use_build_context_synchronously
      //ScaffoldMessenger.of(context).showSnackBar(
      //  const SnackBar(content: Text('Impossibile aprire il video.')),
      //);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = item.controller;
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────── Anteprima video ───────────
            SizedBox(
              width: 260,
              child: ctrl.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: ctrl.value.aspectRatio,
                      child: VideoPlayer(ctrl),
                    )
                  : const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
            const SizedBox(width: 16),
            // ─────────── Descrizione + bottone ───────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(item.description,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow),
                      tooltip: 'Apri video nel browser',
                      onPressed: () => _openInBrowser(item.url),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
