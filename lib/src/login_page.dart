import 'package:flutter/material.dart';
import 'package:webrtc3/src/list_users.dart';
import 'package:webrtc3/src/remotes.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final TextEditingController _loginController = TextEditingController();
  final Remotes _remotes = Remotes();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: _loginWidget(context),
    );
  }

  Widget _loginWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextFormField(
            controller: _loginController,
          ),
          ElevatedButton(
            onPressed: () {
              _remotes.createUser(_loginController.text);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ListUsers(login: _loginController.text)));
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
