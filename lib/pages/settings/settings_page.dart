import 'dart:math' as math;

import 'package:app_analisi_cute/backend_sdk/analyze.dart';
import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:app_analisi_cute/backend_sdk/users.dart';
import 'package:flutter/material.dart';

class ImpostazioniCentroPage extends StatefulWidget {
  final String username;
  final String password;

  const ImpostazioniCentroPage(
      {Key? key, required this.username, required this.password})
      : super(key: key);

  @override
  _ImpostazioniCentroPageState createState() => _ImpostazioniCentroPageState();
}

class _ImpostazioniCentroPageState extends State<ImpostazioniCentroPage> {
  // Controller per le informazioni del centro (inizialmente vuoti)
  final TextEditingController _nomeCentroController = TextEditingController();
  final TextEditingController _indirizzoController = TextEditingController();
  final TextEditingController _numDipendentiController =
      TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _nomeResponsabileController =
      TextEditingController();
  final TextEditingController _orariAperturaController =
      TextEditingController();
  final TextEditingController _orariChiusuraController =
      TextEditingController();

  // Controller per l'Admin Dashboard (creazione utenti)
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailUtenteController = TextEditingController();

  // Lista utenti recuperati dall'API
  List<Map<String, dynamic>> _users = [];

  // Stato per la visibilità della password (creazione)
  bool _passwordVisible = false;

  // Istanza dello SDK
  final Api4Sdk api4 = Api4Sdk();
  final AnalysisApi _analysisApi = AnalysisApi();
  final AnagraficaApi _anagraficaApi = AnagraficaApi();

  // Stato storico admin
  String? _selectedHistoryUsername;
  bool _isHistoryLoading = false;
  String? _historyError;
  Map<String, dynamic>? _loginHistoryPage;
  Map<String, dynamic>? _analysisHistoryPage;
  Map<String, dynamic>? _anagraficheHistoryPage;
  int _loginPage = 1;
  int _analysisPage = 1;
  int _anagrafichePage = 1;
  static const int _historyPageSize = 5;
  int _usersPage = 1;
  static const int _usersPageSize = 5;

  // Stato confronto grafici multi-utente
  final Set<String> _chartSelectedUsers = <String>{};
  bool _selectAllChartUsers = true;
  DateTime? _chartStartDate;
  DateTime? _chartEndDate;
  bool _isChartLoading = false;
  String? _chartError;
  Map<String, int> _loginCountsByUser = <String, int>{};
  Map<String, int> _analysisCountsByUser = <String, int>{};
  Map<String, int> _anagraficheCountsByUser = <String, int>{};

  // Stato confronto utenti (grafico a barre)
  final TextEditingController _comparisonFromDateController =
      TextEditingController();
  final TextEditingController _comparisonToDateController =
      TextEditingController();
  final Set<String> _comparisonSelectedUsers = <String>{};
  bool _comparisonShowAccessi = true;
  bool _comparisonShowAnalisi = true;
  bool _comparisonShowAnagrafiche = true;
  bool _comparisonLoading = false;
  String? _comparisonError;
  Map<String, Map<String, int>> _comparisonCountsByUser = {};

  // Credenziali admin (username e password "admin")
// final String adminUsername = 'admin';
// final String adminPassword = 'admin';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _loadUserMetadata();
  }

  // Funzione per caricare i metadata dell'utente corrente (in questo caso "admin")
  Future<void> _loadUserMetadata() async {
    try {
      // Utilizza il nuovo endpoint "/me" per ottenere i dati personali dell'utente
      final userData = await api4.getOwnData(
        username: widget.username,
        password: widget.password,
      );
      if (userData['metadata'] != null) {
        final metadata = userData['metadata'] as Map<String, dynamic>;
        setState(() {
          _nomeCentroController.text = metadata['nomeCentro'] ?? '';
          _indirizzoController.text = metadata['indirizzo'] ?? '';
          _numDipendentiController.text = metadata['numDipendenti'] ?? '';
          _telefonoController.text = metadata['telefono'] ?? '';
          _mailController.text = metadata['email'] ?? '';
          _nomeResponsabileController.text = metadata['nomeResponsabile'] ?? '';
          _orariAperturaController.text = metadata['orariApertura'] ?? '';
          _orariChiusuraController.text = metadata['orariChiusura'] ?? '';
        });
      }
    } catch (e) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //  SnackBar(content: Text('Errore nel caricamento dei dati personali: $e')),
      //);
    }
  }

  // Funzione per salvare le impostazioni del centro come metadata dell'utente
  Future<void> _saveSettings() async {
    try {
      await api4.updateUser(
        username: widget.username,
        metadata: {
          'nomeCentro': _nomeCentroController.text,
          'indirizzo': _indirizzoController.text,
          'numDipendenti': _numDipendentiController.text,
          'telefono': _telefonoController.text,
          'email': _mailController.text,
          'nomeResponsabile': _nomeResponsabileController.text,
          'orariApertura': _orariAperturaController.text,
          'orariChiusura': _orariChiusuraController.text,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impostazioni salvate con successo!')),
      );
      // Ricarica i metadata dopo il salvataggio
      await _loadUserMetadata();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Errore nel salvataggio delle impostazioni: $e')),
      );
    }
  }

  // Recupera la lista degli utenti tramite l'endpoint admin
  Future<void> _fetchUsers() async {
    try {
      final accounts = await api4.getAllAccounts(
          adminUsername: widget.username, adminPassword: widget.password);
      final parsedUsers = List<Map<String, dynamic>>.from(accounts);
      String? nextSelectedUsername = _selectedHistoryUsername;

      final usernames = parsedUsers
          .map((u) => (u['username'] ?? '').toString())
          .where((u) => u.isNotEmpty)
          .toList();

      final availableUsernameSet = usernames.toSet();
      _chartSelectedUsers.removeWhere((u) => !availableUsernameSet.contains(u));
      if (_selectAllChartUsers || _chartSelectedUsers.isEmpty) {
        _chartSelectedUsers
          ..clear()
          ..addAll(usernames);
        _selectAllChartUsers = true;
      }

      if (nextSelectedUsername == null ||
          !usernames.contains(nextSelectedUsername)) {
        nextSelectedUsername = usernames.isNotEmpty ? usernames.first : null;
      }

      setState(() {
        _users = parsedUsers;
        _selectedHistoryUsername = nextSelectedUsername;
        final totalPages =
            (_users.length + _usersPageSize - 1) ~/ _usersPageSize;
        if (totalPages == 0) {
          _usersPage = 1;
        } else if (_usersPage > totalPages) {
          _usersPage = totalPages;
        }
      });

      if (_isCurrentUserAdmin && _selectedHistoryUsername != null) {
        await _loadAllHistories(resetPages: true);
      }
      if (_isCurrentUserAdmin) {
        await _refreshComparisonCharts();
      }
    } catch (e) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //  SnackBar(content: Text('Errore nel recupero degli utenti: $e')),
      //);
    }
  }

  bool get _isCurrentUserAdmin => widget.username.toUpperCase() == 'ADMIN';

  Future<void> _loadAllHistories({bool resetPages = false}) async {
    final targetUsername = _selectedHistoryUsername;
    if (!_isCurrentUserAdmin ||
        targetUsername == null ||
        targetUsername.isEmpty) {
      return;
    }

    if (resetPages) {
      _loginPage = 1;
      _analysisPage = 1;
      _anagrafichePage = 1;
    }

    setState(() {
      _isHistoryLoading = true;
      _historyError = null;
    });

    try {
      final responses = await Future.wait([
        api4.getAdminLoginHistory(
          targetUsername: targetUsername,
          adminUsername: widget.username,
          adminPassword: widget.password,
          page: _loginPage,
          pageSize: _historyPageSize,
        ),
        _analysisApi.getAdminUserAnalysisHistory(
          targetUsername: targetUsername,
          adminUsername: widget.username,
          adminPassword: widget.password,
          page: _analysisPage,
          pageSize: _historyPageSize,
        ),
        _anagraficaApi.getAdminUserAnagraficheHistory(
          targetUsername: targetUsername,
          adminUsername: widget.username,
          adminPassword: widget.password,
          page: _anagrafichePage,
          pageSize: _historyPageSize,
        ),
      ]);

      setState(() {
        _loginHistoryPage = responses[0];
        _analysisHistoryPage = responses[1];
        _anagraficheHistoryPage = responses[2];
        _isHistoryLoading = false;
      });
    } catch (e) {
      setState(() {
        _isHistoryLoading = false;
        _historyError = e.toString();
      });
    }
  }

  List<dynamic> _historyItems(Map<String, dynamic>? pageData) {
    if (pageData == null) return [];
    final dynamic items = pageData['items'];
    if (items is List) {
      return items;
    }
    return [];
  }

  int _historyCurrentPage(Map<String, dynamic>? pageData) {
    if (pageData == null) return 1;
    final dynamic value = pageData['page'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  int _historyTotalPages(Map<String, dynamic>? pageData) {
    if (pageData == null) return 1;
    final dynamic value = pageData['total_pages'];
    if (value is int) return value > 0 ? value : 1;
    if (value is String) {
      final parsed = int.tryParse(value) ?? 1;
      return parsed > 0 ? parsed : 1;
    }
    return 1;
  }

  int _historyTotalItems(Map<String, dynamic>? pageData) {
    if (pageData == null) return 0;
    final dynamic value = pageData['total_items'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _safeText(dynamic value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _summaryTitle(
      String historyType, Map<String, dynamic> item, int index) {
    switch (historyType) {
      case 'login':
        return 'Accesso #${index + 1}';
      case 'analysis':
        final nome = _safeText(item['nome'], fallback: 'Utente');
        final cognome = _safeText(item['cognome'], fallback: '');
        return '$nome $cognome'.trim();
      case 'anagrafiche':
        final nome = _safeText(item['nome'], fallback: 'Nominativo');
        final cognome = _safeText(item['cognome'], fallback: '');
        return '$nome $cognome'.trim();
      default:
        return 'Elemento #${index + 1}';
    }
  }

  List<MapEntry<String, String>> _summaryDetails(
      String historyType, Map<String, dynamic> item) {
    switch (historyType) {
      case 'login':
        return [
          MapEntry('Data/Ora', _safeText(item['timestamp'])),
        ];
      case 'analysis':
        final dynamic result = item['result'];
        final parametersCount = result is Map ? result.length.toString() : '0';
        return [
          MapEntry('Data/Ora', _safeText(item['timestamp'])),
          MapEntry('Parametri', parametersCount),
          MapEntry('Origine', _safeText(item['source_user'])),
        ];
      case 'anagrafiche':
        return [
          MapEntry('Nascita', _safeText(item['birth_date'])),
          MapEntry('Genere', _safeText(item['gender'])),
          MapEntry('Origine', _safeText(item['source_user'])),
          MapEntry('Creata il', _safeText(item['created_at'])),
        ];
      default:
        return [
          MapEntry('Dettaglio', _safeText(item)),
        ];
    }
  }

  IconData _historyIcon(String historyType) {
    switch (historyType) {
      case 'login':
        return Icons.login_rounded;
      case 'analysis':
        return Icons.analytics_rounded;
      case 'anagrafiche':
        return Icons.badge_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _historyAccentColor(String historyType) {
    switch (historyType) {
      case 'login':
        return Colors.indigo;
      case 'analysis':
        return Colors.teal;
      case 'anagrafiche':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }

  void _showHistoryDetailDialog({
    required String historyType,
    required String title,
    required Map<String, dynamic> item,
  }) {
    final accent = _historyAccentColor(historyType);
    final dynamic result = item['result'];
    final filteredEntries = item.entries.where(
      (entry) =>
          entry.key != 'result' &&
          entry.key != 'patient_ref' &&
          entry.key != 'analysis_history',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _summaryDetails(historyType, item)
                        .map(
                          (entry) => Chip(
                            backgroundColor: accent.withOpacity(0.08),
                            side: BorderSide(color: accent.withOpacity(0.25)),
                            label: Text('${entry.key}: ${entry.value}'),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dettagli completi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...filteredEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(_safeText(entry.value)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (result is Map &&
                      result.isNotEmpty &&
                      historyType == 'analysis') ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Risultato analisi',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ..._buildAnalysisDetailCards(result),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CHIUDI'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryCard({
    required String historyType,
    required Map<String, dynamic> item,
    required int index,
  }) {
    final accent = _historyAccentColor(historyType);
    final title = _summaryTitle(historyType, item, index);
    final details = _summaryDetails(historyType, item);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showHistoryDetailDialog(
          historyType: historyType,
          title: title,
          item: item,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_historyIcon(historyType), color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: details
                          .map(
                            (entry) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnalysisDetailCards(Map<dynamic, dynamic> result) {
    return result.entries.map((entry) {
      final String metricName = _safeText(entry.key);
      final Map<String, dynamic> metricData = entry.value is Map
          ? Map<String, dynamic>.from(entry.value as Map)
          : <String, dynamic>{'descrizione': _safeText(entry.value)};

      final dynamic rawValue = metricData['valore'];
      final double? numericValue = rawValue is num
          ? rawValue.toDouble()
          : double.tryParse(rawValue?.toString() ?? '');

      final String descrizione = _safeText(metricData['descrizione']);
      final String valutazione = _safeText(
        metricData['valutazione_professionale'] ?? metricData['valutazione'],
      );
      final String consigli = _safeText(metricData['consigli']);
      final normalizedMetricName = metricName.toLowerCase();
      final isBodyZoneMetric = normalizedMetricName.contains('body zone') ||
          normalizedMetricName.contains('body_zone') ||
          normalizedMetricName.contains('zona');

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    metricName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                if (numericValue != null)
                  Text(
                    '${numericValue.toStringAsFixed(0)}/100',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            if (numericValue != null) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (numericValue.clamp(0, 100)) / 100,
                minHeight: 7,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black87),
              ),
            ],
            const SizedBox(height: 8),
            Text('Descrizione: $descrizione'),
            if (!isBodyZoneMetric) ...[
              const SizedBox(height: 4),
              Text('Valutazione: $valutazione'),
              const SizedBox(height: 4),
              Text('Consigli: $consigli'),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildHistorySection({
    required String title,
    required String historyType,
    required Map<String, dynamic>? pageData,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    final items = _historyItems(pageData)
        .map((e) =>
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))
        .toList();
    final page = _historyCurrentPage(pageData);
    final totalPages = _historyTotalPages(pageData);
    final totalItems = _historyTotalItems(pageData);

    return _buildContainerWithBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalItems elementi',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'Nessun elemento disponibile.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...items.asMap().entries.map(
                  (entry) => _buildHistoryCard(
                    historyType: historyType,
                    item: entry.value,
                    index: entry.key + ((page - 1) * _historyPageSize),
                  ),
                ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$_historyPageSize card/pagina',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Text('Pagina $page / $totalPages'),
              const SizedBox(width: 8),
              IconButton(
                onPressed: page > 1 ? onPrev : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: page < totalPages ? onNext : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime? _parseHistoryDate(dynamic rawValue) {
    final value = rawValue?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  bool _isWithinSelectedDateRange(DateTime? date) {
    final start = _chartStartDate == null
        ? null
        : DateTime(_chartStartDate!.year, _chartStartDate!.month,
            _chartStartDate!.day);
    final end = _chartEndDate == null
        ? null
        : DateTime(
            _chartEndDate!.year, _chartEndDate!.month, _chartEndDate!.day);

    if (start == null && end == null) return true;
    if (date == null) return false;
    final onlyDate = DateTime(date.year, date.month, date.day);

    if (start != null && onlyDate.isBefore(start)) return false;
    if (end != null && onlyDate.isAfter(end)) return false;
    return true;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_chartStartDate ?? DateTime.now())
        : (_chartEndDate ?? _chartStartDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Data inizio' : 'Data fine',
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _chartStartDate = picked;
        if (_chartEndDate != null && _chartEndDate!.isBefore(picked)) {
          _chartEndDate = picked;
        }
      } else {
        _chartEndDate = picked;
      }
    });

    await _refreshComparisonCharts();
  }

  Future<List<Map<String, dynamic>>> _fetchAllPaginatedItems({
    required Future<Map<String, dynamic>> Function(int page, int pageSize)
        pageLoader,
    int pageSize = 200,
  }) async {
    final List<Map<String, dynamic>> allItems = [];
    int currentPage = 1;
    int totalPages = 1;

    do {
      final pageData = await pageLoader(currentPage, pageSize);
      final pageItems = _historyItems(pageData)
          .map((item) => item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item as Map))
          .toList();
      allItems.addAll(pageItems);
      totalPages = _historyTotalPages(pageData);
      currentPage++;
    } while (currentPage <= totalPages);

    return allItems;
  }

  Future<Map<String, int>> _buildUserComparisonCounts(String username) async {
    final loginItems = await _fetchAllPaginatedItems(
      pageLoader: (page, pageSize) => api4.getAdminLoginHistory(
        targetUsername: username,
        adminUsername: widget.username,
        adminPassword: widget.password,
        page: page,
        pageSize: pageSize,
      ),
    );

    final analysisItems = await _fetchAllPaginatedItems(
      pageLoader: (page, pageSize) => _analysisApi.getAdminUserAnalysisHistory(
        targetUsername: username,
        adminUsername: widget.username,
        adminPassword: widget.password,
        page: page,
        pageSize: pageSize,
      ),
    );

    final anagraficheItems = await _fetchAllPaginatedItems(
      pageLoader: (page, pageSize) =>
          _anagraficaApi.getAdminUserAnagraficheHistory(
        targetUsername: username,
        adminUsername: widget.username,
        adminPassword: widget.password,
        page: page,
        pageSize: pageSize,
      ),
    );

    final loginCount = loginItems
        .where((item) =>
            _isWithinSelectedDateRange(_parseHistoryDate(item['timestamp'])))
        .length;
    final analysisCount = analysisItems
        .where((item) =>
            _isWithinSelectedDateRange(_parseHistoryDate(item['timestamp'])))
        .length;
    final anagraficheCount = anagraficheItems
        .where((item) =>
            _isWithinSelectedDateRange(_parseHistoryDate(item['created_at'])))
        .length;

    return {
      'login': loginCount,
      'analysis': analysisCount,
      'anagrafiche': anagraficheCount,
    };
  }

  Future<void> _refreshComparisonCharts() async {
    if (!_isCurrentUserAdmin) return;

    final selectedUsers = _chartSelectedUsers.toList()..sort();
    if (selectedUsers.isEmpty) {
      setState(() {
        _loginCountsByUser = {};
        _analysisCountsByUser = {};
        _anagraficheCountsByUser = {};
        _chartError = null;
      });
      return;
    }

    setState(() {
      _isChartLoading = true;
      _chartError = null;
    });

    try {
      final results = await Future.wait(
        selectedUsers.map(_buildUserComparisonCounts),
      );

      final Map<String, int> login = {};
      final Map<String, int> analysis = {};
      final Map<String, int> anagrafiche = {};

      for (var i = 0; i < selectedUsers.length; i++) {
        final username = selectedUsers[i];
        final data = results[i];
        login[username] = data['login'] ?? 0;
        analysis[username] = data['analysis'] ?? 0;
        anagrafiche[username] = data['anagrafiche'] ?? 0;
      }

      setState(() {
        _loginCountsByUser = login;
        _analysisCountsByUser = analysis;
        _anagraficheCountsByUser = anagrafiche;
        _isChartLoading = false;
      });
    } catch (e) {
      setState(() {
        _isChartLoading = false;
        _chartError = e.toString();
      });
    }
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: TextFormField(
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'gg/mm/aaaa',
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        controller: TextEditingController(text: _formatDate(date)),
      ),
    );
  }

  Widget _buildUserSelectionPanel() {
    final usernames = _users
        .map((u) => _safeText(u['username'], fallback: ''))
        .where((u) => u.isNotEmpty)
        .toList()
      ..sort();

    return _buildContainerWithBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Utenti per confronto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _selectAllChartUsers,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Seleziona tutti'),
                  onChanged: (value) async {
                    final shouldSelectAll = value ?? false;
                    setState(() {
                      _selectAllChartUsers = shouldSelectAll;
                      _chartSelectedUsers
                        ..clear()
                        ..addAll(shouldSelectAll ? usernames : <String>[]);
                    });
                    await _refreshComparisonCharts();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 260,
            child: usernames.isEmpty
                ? const Center(
                    child: Text(
                      'Nessun utente disponibile.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: usernames.length,
                    itemBuilder: (context, index) {
                      final username = usernames[index];
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _chartSelectedUsers.contains(username),
                        title: Text(username),
                        onChanged: (value) async {
                          setState(() {
                            if (value ?? false) {
                              _chartSelectedUsers.add(username);
                            } else {
                              _chartSelectedUsers.remove(username);
                            }
                            _selectAllChartUsers = usernames.isNotEmpty &&
                                _chartSelectedUsers.length == usernames.length;
                          });
                          await _refreshComparisonCharts();
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDateField(
                label: 'Data inizio',
                date: _chartStartDate,
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(width: 10),
              _buildDateField(
                label: 'Data fine',
                date: _chartEndDate,
                onTap: () => _pickDate(isStart: false),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isChartLoading ? null : _refreshComparisonCharts,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
              label: const Text(
                'AGGIORNA GRAFICI',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBarChart({
    required String title,
    required String subtitle,
    required Map<String, int> data,
    required Color barColor,
  }) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = entries.isEmpty
        ? 1
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return _buildContainerWithBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              'Seleziona almeno un utente per vedere il grafico.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...entries.map(
              (entry) {
                final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          entry.key,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${entry.value}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonChartsSection() {
    final subtitle =
        'Intervallo: ${_chartStartDate == null ? 'inizio libero' : _formatDate(_chartStartDate)} - ${_chartEndDate == null ? 'fine libera' : _formatDate(_chartEndDate)}';

    final rightContent = Column(
      children: [
        _buildComparisonBarChart(
          title: 'Accessi eseguiti per utente',
          subtitle: subtitle,
          data: _loginCountsByUser,
          barColor: Colors.indigo,
        ),
        const SizedBox(height: 12),
        _buildComparisonBarChart(
          title: 'Anagrafiche create per utente',
          subtitle: subtitle,
          data: _anagraficheCountsByUser,
          barColor: Colors.deepOrange,
        ),
        const SizedBox(height: 12),
        _buildComparisonBarChart(
          title: 'Analisi eseguite per utente',
          subtitle: subtitle,
          data: _analysisCountsByUser,
          barColor: Colors.teal,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confronto utenti (grafici a barre)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_isChartLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_chartError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Errore caricamento grafici: $_chartError',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1000) {
              return Column(
                children: [
                  _buildUserSelectionPanel(),
                  const SizedBox(height: 12),
                  rightContent,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: _buildUserSelectionPanel()),
                const SizedBox(width: 12),
                Expanded(child: rightContent),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminDashboardTab() {
    final totalUserPages =
        (_users.length + _usersPageSize - 1) ~/ _usersPageSize;
    final safeTotalUserPages = totalUserPages > 0 ? totalUserPages : 1;
    final start = (_usersPage - 1) * _usersPageSize;
    final end = (start + _usersPageSize) > _users.length
        ? _users.length
        : (start + _usersPageSize);
    final pagedUsers = (start >= 0 && start < _users.length)
        ? _users.sublist(start, end)
        : <Map<String, dynamic>>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestione Utenti',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildContainerWithBorder(
            child: Column(
              children: [
                _buildTextField('Username', _usernameController),
                _buildPasswordTextField('Password', _passwordController),
                _buildTextField('Email', _emailUtenteController),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _createUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'CREA UTENTE',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Lista Utenti',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildContainerWithBorder(
            child: Column(
              children: [
                if (_users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Nessun utente creato.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Column(
                    children: pagedUsers.map((user) {
                      final username = (user['username'] ?? '').toString();
                      final isSelected = username.isNotEmpty &&
                          username == _selectedHistoryUsername;

                      return Card(
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListTile(
                          onTap: () async {
                            if (username.isEmpty) return;
                            setState(() {
                              _selectedHistoryUsername = username;
                            });
                            await _loadAllHistories(resetPages: true);
                          },
                          title: Text(username),
                          subtitle: Text(
                            'Email: ${user['metadata'] != null ? user['metadata']['email'] ?? '' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.info, color: Colors.blue),
                                onPressed: () => _viewUserInfo(user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange),
                                onPressed: () => _editUser(user),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(username),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$_usersPageSize utenti/pagina • Pagina $_usersPage / $safeTotalUserPages',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _usersPage > 1
                          ? () {
                              setState(() {
                                _usersPage -= 1;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      onPressed: _usersPage < safeTotalUserPages
                          ? () {
                              setState(() {
                                _usersPage += 1;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Storici utente selezionato',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_selectedHistoryUsername == null)
            const Text(
              'Seleziona un utente dalla lista per visualizzare gli storici.',
              style: TextStyle(color: Colors.grey),
            )
          else ...[
            Text('Utente selezionato: $_selectedHistoryUsername'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isHistoryLoading ? null : () => _loadAllHistories(),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('AGGIORNA',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              ),
            ),
            if (_isHistoryLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_historyError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Errore caricamento storici: $_historyError',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            _buildHistorySection(
              title: 'Storico Accessi (Auth API)',
              historyType: 'login',
              pageData: _loginHistoryPage,
              onPrev: () async {
                if (_loginPage > 1) {
                  _loginPage -= 1;
                  await _loadAllHistories();
                }
              },
              onNext: () async {
                final total = _historyTotalPages(_loginHistoryPage);
                if (_loginPage < total) {
                  _loginPage += 1;
                  await _loadAllHistories();
                }
              },
            ),
            const SizedBox(height: 12),
            _buildHistorySection(
              title: 'Storico Analisi (Agents API)',
              historyType: 'analysis',
              pageData: _analysisHistoryPage,
              onPrev: () async {
                if (_analysisPage > 1) {
                  _analysisPage -= 1;
                  await _loadAllHistories();
                }
              },
              onNext: () async {
                final total = _historyTotalPages(_analysisHistoryPage);
                if (_analysisPage < total) {
                  _analysisPage += 1;
                  await _loadAllHistories();
                }
              },
            ),
            const SizedBox(height: 12),
            _buildHistorySection(
              title: 'Storico Anagrafiche (Patients API)',
              historyType: 'anagrafiche',
              pageData: _anagraficheHistoryPage,
              onPrev: () async {
                if (_anagrafichePage > 1) {
                  _anagrafichePage -= 1;
                  await _loadAllHistories();
                }
              },
              onNext: () async {
                final total = _historyTotalPages(_anagraficheHistoryPage);
                if (_anagrafichePage < total) {
                  _anagrafichePage += 1;
                  await _loadAllHistories();
                }
              },
            ),
            const SizedBox(height: 24),
            _buildComparisonChartsSection(),
          ],
        ],
      ),
    );
  }

  // Crea un utente utilizzando l'endpoint register
  Future<void> _createUser() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _emailUtenteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Compila tutti i campi per creare un utente!')),
      );
      return;
    }
    try {
      await api4.registerUser(
        username: _usernameController.text,
        password: _passwordController.text,
        metadata: {'email': _emailUtenteController.text},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utente creato con successo!')),
      );
      // Svuota i campi di input
      _usernameController.clear();
      _passwordController.clear();
      _emailUtenteController.clear();
      // Aggiorna la lista degli utenti
      _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella creazione dell\'utente: $e')),
      );
    }
  }

  // Elimina un utente utilizzando l'endpoint admin per la cancellazione
  Future<void> _deleteUser(String username) async {
    try {
      await api4.adminDeleteUser(
          targetUsername: username,
          adminUsername: widget.username,
          adminPassword: widget.password);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utente eliminato con successo!')),
      );
      _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nell\'eliminazione dell\'utente: $e')),
      );
    }
  }

  // Modifica un utente (aggiornamento password e/o email) tramite API
  Future<void> _editUser(Map<String, dynamic> user) async {
    // Mostra un dialog per modificare le informazioni dell'utente
    // Nota: il campo username non è modificabile
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController emailController = TextEditingController(
      text: user['metadata'] != null ? user['metadata']['email'] ?? '' : '',
    );
    bool _localPasswordVisible = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Modifica Utente - ${user['username']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Visualizza username (non editabile)
                  Text('Username: ${user['username']}'),
                  const SizedBox(height: 12),
                  // Campo password (lasciare vuoto se non si vuole cambiare)
                  TextField(
                    controller: passwordController,
                    obscureText: !_localPasswordVisible,
                    decoration: InputDecoration(
                      labelText:
                          'Nuova Password (lascia vuoto per non cambiare)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_localPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setStateDialog(() {
                            _localPasswordVisible = !_localPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Campo email
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ANNULLA'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    // Se è stata inserita una nuova password, usa l'endpoint adminChangePassword
                    if (passwordController.text.isNotEmpty) {
                      await api4.adminChangePassword(
                        targetUsername: user['username'],
                        adminUsername: widget.username,
                        adminPassword: widget.password,
                        newPassword: passwordController.text,
                      );
                    }
                    // Aggiorna i metadata (in questo caso, l'email) usando l'endpoint update
                    await api4.updateUser(
                      username: user['username'],
                      metadata: {'email': emailController.text},
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Utente aggiornato con successo!')),
                    );
                    Navigator.of(context).pop();
                    _fetchUsers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Errore nell\'aggiornamento dell\'utente: $e')),
                    );
                  }
                },
                child: const Text('SALVA'),
              ),
            ],
          );
        });
      },
    );
  }

  // Visualizza le informazioni di un utente in un dialog
  void _viewUserInfo(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        // Ottieni i metadata o un Map vuoto se non esistono
        final Map<String, dynamic> metadata =
            (user['metadata'] as Map<String, dynamic>?) ?? {};
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Informazioni Utente - ${user['username']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username: ${user['username']}'),
                const SizedBox(height: 8),
                // Visualizza ogni coppia chiave-valore dei metadata
                ...metadata.entries.map(
                  (entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key}: ${entry.value}'),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Text('Password: ${user['hashed_password'] ?? 'N/A'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CHIUDI'),
            ),
          ],
        );
      },
    );
  }

  // Widget riutilizzabile per un container con bordo
  Widget _buildContainerWithBorder({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }

  // Widget riutilizzabile per un text field
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  // Widget riutilizzabile per un text field password
  Widget _buildPasswordTextField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        obscureText: !_passwordVisible,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          suffixIcon: IconButton(
            icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _isCurrentUserAdmin;
    final List<Tab> tabs = [
      const Tab(text: 'Informazioni Utente'),
      if (isAdmin) const Tab(text: 'Admin Dashboard'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Impostazioni Centro',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.grey.withOpacity(0.4),
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: tabs,
          ),
        ),
        body: Container(
          color: Colors.white,
          child: TabBarView(
            children: [
              // Tab: Informazioni Utente (dati del centro)
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildContainerWithBorder(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modifica Informazioni Centro',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('Nome del Centro', _nomeCentroController),
                      _buildTextField('Indirizzo', _indirizzoController),
                      _buildTextField(
                          'Numero Dipendenti', _numDipendentiController),
                      _buildTextField('Telefono', _telefonoController),
                      _buildTextField('Email', _mailController),
                      _buildTextField('Nome e Cognome Responsabile',
                          _nomeResponsabileController),
                      _buildTextField(
                          'Orario Apertura', _orariAperturaController),
                      _buildTextField(
                          'Orario Chiusura', _orariChiusuraController),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'SALVA',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isAdmin) _buildAdminDashboardTab(),
            ],
          ),
        ),
      ),
    );
  }
}
