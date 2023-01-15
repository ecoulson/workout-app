import 'package:flutter/material.dart';

import '../phoenix_channel_client/phoenix_channel_client.dart';
import 'machine_creation_page.dart';

class RepititionCounterPage extends StatefulWidget {
  final String machineId;

  const RepititionCounterPage({Key? key, required this.machineId})
      : super(key: key);

  @override
  State<RepititionCounterPage> createState() => _RepititionCounterPageState();
}

class _RepititionCounterPageState extends State<RepititionCounterPage> {
  int _counter = 0;
  bool _connected = false;
  final socket = PhoenixSocket("ws://localhost:4000/socket/websocket");

  Future<void> _connect() async {
    if (!_connected) {
      await socket.connect();

      final workoutChannel = socket.channel("machine:${widget.machineId}", {});

      workoutChannel.on("repitition",
          (Map? payload, String? ref, String? joinRef) {
        _incrementCounter();
      });
      setState(() {
        _connected = true;
      });

      workoutChannel.join();
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _onTap() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const MachineCreationPage()));
  }

  @override
  Widget build(BuildContext context) {
    _connect();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Repitition Counter"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(onPressed: _onTap, child: const Text("Create Tag")),
            const Text(
              'Repititions:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
    );
  }
}
