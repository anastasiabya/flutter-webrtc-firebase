import 'package:flutter/material.dart';
import 'package:webrtc3/src/call.dart';

class ListUsers extends StatelessWidget {
  const ListUsers({
    Key? key,
    this.login,
  }) : super(key: key);

  final String? login;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebRTC calls'),
      ),
      body: Container(
        height: 300,
        child: ListView(
          children: [
            ListTile(
              title: const Text('max'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Calls(
                            caller: login,
                            callee: 'max',
                          ))),
            ),
            ListTile(
              title: const Text('anastasia'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Calls(
                            caller: login,
                            callee: 'anastasia',
                          ))),
            ),
            ListTile(
              title: const Text('oleg'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Calls(
                            caller: login,
                            callee: 'oleg',
                          ))),
            ),
          ],
        ),
      ),
    );
  }
}
