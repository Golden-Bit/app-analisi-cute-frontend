import 'package:app_analisi_cute/backend_sdk/users.dart';
import 'package:flutter/material.dart';

class ImpostazioniCentroPage extends StatefulWidget {
  final String username;
  final String password;

  const ImpostazioniCentroPage({Key? key, required this.username, required this.password}) : super(key: key);

  @override
  _ImpostazioniCentroPageState createState() => _ImpostazioniCentroPageState();
}

class _ImpostazioniCentroPageState extends State<ImpostazioniCentroPage> {
  // Controller per le informazioni del centro (inizialmente vuoti)
  final TextEditingController _nomeCentroController = TextEditingController();
  final TextEditingController _indirizzoController = TextEditingController();
  final TextEditingController _numDipendentiController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _nomeResponsabileController = TextEditingController();
  final TextEditingController _orariAperturaController = TextEditingController();
  final TextEditingController _orariChiusuraController = TextEditingController();

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
        SnackBar(content: Text('Errore nel salvataggio delle impostazioni: $e')),
      );
    }
  }

  // Recupera la lista degli utenti tramite l'endpoint admin
  Future<void> _fetchUsers() async {
    try {
      final accounts = await api4.getAllAccounts(
          adminUsername: widget.username, adminPassword: widget.password);
      setState(() {
        _users = List<Map<String, dynamic>>.from(accounts);
      });
    } catch (e) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //  SnackBar(content: Text('Errore nel recupero degli utenti: $e')),
      //);
    }
  }

  // Crea un utente utilizzando l'endpoint register
  Future<void> _createUser() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _emailUtenteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi per creare un utente!')),
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
                      labelText: 'Nuova Password (lascia vuoto per non cambiare)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_localPasswordVisible ? Icons.visibility : Icons.visibility_off),
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
                      const SnackBar(content: Text('Utente aggiornato con successo!')),
                    );
                    Navigator.of(context).pop();
                    _fetchUsers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Errore nell\'aggiornamento dell\'utente: $e')),
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
  Widget _buildPasswordTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        obscureText: !_passwordVisible,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          suffixIcon: IconButton(
            icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
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
    final bool isAdmin = widget.username == 'admin';
    return DefaultTabController(
      length: isAdmin ? 2 : 1, // Due tab: Informazioni Utente e Admin Dashboard
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
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Informazioni Utente'),
              Tab(text: 'Admin Dashboard'),
            ],
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('Nome del Centro', _nomeCentroController),
                      _buildTextField('Indirizzo', _indirizzoController),
                      _buildTextField('Numero Dipendenti', _numDipendentiController),
                      _buildTextField('Telefono', _telefonoController),
                      _buildTextField('Email', _mailController),
                      _buildTextField('Nome e Cognome Responsabile', _nomeResponsabileController),
                      _buildTextField('Orario Apertura', _orariAperturaController),
                      _buildTextField('Orario Chiusura', _orariChiusuraController),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              // Tab: Admin Dashboard
              SingleChildScrollView(
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
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                                    return Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: ListTile(
                                        title: Text(user['username'] ?? ''),
                                        subtitle: Text('Email: ${user['metadata'] != null ? user['metadata']['email'] ?? '' : ''}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.info, color: Colors.blue),
                                              onPressed: () => _viewUserInfo(user),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.orange),
                                              onPressed: () => _editUser(user),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteUser(user['username'] ?? ''),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
