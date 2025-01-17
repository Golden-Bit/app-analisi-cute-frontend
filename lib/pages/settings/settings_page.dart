import 'package:flutter/material.dart';

class ImpostazioniCentroPage extends StatefulWidget {
  const ImpostazioniCentroPage({Key? key}) : super(key: key);

  @override
  _ImpostazioniCentroPageState createState() => _ImpostazioniCentroPageState();
}

class _ImpostazioniCentroPageState extends State<ImpostazioniCentroPage> {
  // Controller per Informazioni Utente
  final TextEditingController _nomeCentroController =
      TextEditingController(text: 'Centro Estetico Bellezza');
  final TextEditingController _indirizzoController =
      TextEditingController(text: 'Via Roma 123, Milano');
  final TextEditingController _numDipendentiController =
      TextEditingController(text: '15');
  final TextEditingController _telefonoController =
      TextEditingController(text: '+39 012 3456 7890');
  final TextEditingController _mailController =
      TextEditingController(text: 'info@centrobellezza.com');
  final TextEditingController _nomeResponsabileController =
      TextEditingController(text: 'Mario Rossi');
  final TextEditingController _orariAperturaController =
      TextEditingController(text: '09:00');
  final TextEditingController _orariChiusuraController =
      TextEditingController(text: '19:00');

  // Controller per Admin Dashboard (creazione utenti)
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailUtenteController = TextEditingController();

  // Lista utenti creata
  List<Map<String, String>> _users = [];
  bool _passwordVisible = false; // Stato della visibilità della password

  void _saveSettings() {
    // Logica per salvare le impostazioni
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impostazioni salvate con successo!')),
    );
  }

  void _createUser() {
    // Logica per creare un utente e aggiungerlo alla lista
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _emailUtenteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Compila tutti i campi per creare un utente!')),
      );
      return;
    }

    setState(() {
      _users.add({
        'username': _usernameController.text,
        'password': _passwordController.text,
        'email': _emailUtenteController.text,
      });

      // Svuota i campi dopo la creazione dell'utente
      _usernameController.clear();
      _passwordController.clear();
      _emailUtenteController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Utente creato con successo!')),
    );
  }

  void _deleteUser(int index) {
    setState(() {
      _users.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Utente eliminato con successo!')),
    );
  }

  void _editUser(int index) {
    final user = _users[index];

    // Mostra un dialog per modificare le informazioni dell'utente
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController usernameController =
            TextEditingController(text: user['username']);
        final TextEditingController passwordController =
            TextEditingController(text: user['password']);
        final TextEditingController emailController =
            TextEditingController(text: user['email']);
        bool passwordVisible = false;

        return AlertDialog(
          title: const Text('Modifica Utente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField('Username', usernameController),
                _buildDialogPasswordField(
                  'Password',
                  passwordController,
                  passwordVisible,
                  (bool visible) {
                    setState(() {
                      passwordVisible = visible;
                    });
                  },
                ),
                _buildDialogTextField('Email', emailController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('ANNULLA'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _users[index] = {
                    'username': usernameController.text,
                    'password': passwordController.text,
                    'email': emailController.text,
                  };
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Utente aggiornato con successo!')),
                );
              },
              child: const Text('SALVA'),
            ),
          ],
        );
      },
    );
  }

  void _viewUserInfo(int index) {
    final user = _users[index];

    // Mostra un dialog con tutte le informazioni dell'utente
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Informazioni Utente - ${user['username']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username: ${user['username']}'),
                const SizedBox(height: 8),
                Text('Email: ${user['email']}'),
                const SizedBox(height: 8),
                Text('Password: ${user['password']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CHIUDI'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Due tab: Informazioni Utente e Admin Dashboard
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
      color: Colors.white, // Sfondo bianco
      child: TabBarView(
          children: [
            // Tab: Informazioni Utente
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
      _buildTextField(
          'Nome e Cognome Responsabile', _nomeResponsabileController),
      _buildTextField('Orario Apertura', _orariAperturaController),
      _buildTextField('Orario Chiusura', _orariChiusuraController),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight, // Allineamento a destra
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
                        _buildPasswordTextField(
                            'Password', _passwordController),
                        _buildTextField('Email', _emailUtenteController),
                        const SizedBox(height: 16),
                        Align(
                          alignment:
                              Alignment.centerRight, // Allineamento a sinistra
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
                    'Lista Utenti Creati',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildContainerWithBorder(
                    child: SizedBox(
                      height: 200, // Altezza minima del riquadro
                      child: _users.isEmpty
                          ? const Center(
                              child: Text(
                                'Nessun utente creato.',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
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
                                      title: Text(user['username']!),
                                      subtitle: Text('Email: ${user['email']}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.info,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _viewUserInfo(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.settings,
                                                color: Colors.orange),
                                            onPressed: () => _editUser(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _deleteUser(index),
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
    ));
  }

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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        obscureText: !_passwordVisible,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
            ),
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

  Widget _buildDialogTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogPasswordField(
    String label,
    TextEditingController controller,
    bool passwordVisible,
    ValueChanged<bool> onToggleVisibility,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        obscureText: !passwordVisible,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              passwordVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              onToggleVisibility(!passwordVisible);
            },
          ),
        ),
      ),
    );
  }
}
