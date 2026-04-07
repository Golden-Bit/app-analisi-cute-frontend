import 'dart:convert';

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
  static const int _historyPageSize = 10;

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

      if (nextSelectedUsername == null ||
          !usernames.contains(nextSelectedUsername)) {
        nextSelectedUsername = usernames.isNotEmpty ? usernames.first : null;
      }

      setState(() {
        _users = parsedUsers;
        _selectedHistoryUsername = nextSelectedUsername;
      });

      if (_isCurrentUserAdmin && _selectedHistoryUsername != null) {
        await _loadAllHistories(resetPages: true);
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

  Widget _buildHistorySection({
    required String title,
    required Map<String, dynamic>? pageData,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    final items = _historyItems(pageData);
    final page = _historyCurrentPage(pageData);
    final totalPages = _historyTotalPages(pageData);

    return _buildContainerWithBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'Nessun elemento disponibile.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade100,
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(item),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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

  Widget _buildAdminDashboardTab() {
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
            child: SizedBox(
              height: 300,
              child: _users.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun utente creato.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final username = (user['username'] ?? '').toString();
                          final isSelected = username.isNotEmpty &&
                              username == _selectedHistoryUsername;

                          return Card(
                            color:
                                isSelected ? Colors.blue.shade50 : Colors.white,
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
                                    icon: const Icon(Icons.info,
                                        color: Colors.blue),
                                    onPressed: () => _viewUserInfo(user),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.orange),
                                    onPressed: () => _editUser(user),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteUser(username),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
