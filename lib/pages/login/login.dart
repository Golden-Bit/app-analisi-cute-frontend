import 'package:app_analisi_cute/pages/home/home.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  void _login() {
    const validUsername = 'admin';
    const validPassword = 'admin';

    if (_usernameController.text == validUsername &&
        _passwordController.text == validPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      setState(() {
        _errorMessage = 'Username o password non corretti';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(color: Colors.black), // Testo nero
        ),
        backgroundColor: Colors.white, // Sfondo bianco
        elevation: 4, // Ombra leggera
        shadowColor: Colors.grey.withOpacity(0.4), // Colore dell'ombra
        iconTheme: const IconThemeData(color: Colors.black), // Icone nere
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://static.wixstatic.com/media/63b1fb_f4b32483fdcb4f39a1e294a497dd452a~mv2.png',
                  width: 150, // Larghezza personalizzata per il logo
                  height: 150, // Altezza personalizzata per il logo
                  fit: BoxFit.contain, // Adatta l'immagine senza distorcerla
                ),
                const SizedBox(height: 32), // Spaziatura tra il logo e il form
                SizedBox(
                  width: 300, // Larghezza ridotta del campo username
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 300, // Larghezza ridotta del campo password
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child:
                      const Text('Login', style: TextStyle(color: Colors.white)),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
