import 'package:app/src/pages/repitition_counter_page.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'machine_creation_page.dart';

class ScanTagPage extends StatefulWidget {
  const ScanTagPage({super.key});

  @override
  State<ScanTagPage> createState() => _ScanTagPageState();
}

class _ScanTagPageState extends State<ScanTagPage> {
  void _onCreateTag() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const MachineCreationPage()));
  }

  void _onTagScan() async {
    if (!await NfcManager.instance.isAvailable()) {
      return;
    }
    NfcManager.instance.startSession(
        onDiscovered: (tag) => _onTagRead(tag, Navigator.of(context)));
    Navigator.push(context,
        MaterialPageRoute(builder: ((context) => const ScanTagPage())));
  }

  Future<void> _onTagRead(NfcTag tag, NavigatorState navigatorState) async {
    print(tag.data);
    navigatorState.push(MaterialPageRoute(
        builder: ((context) => const RepititionCounterPage(
              machineId: "0",
            ))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Tag"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
                onPressed: _onCreateTag, child: const Text("Create Tag")),
            ElevatedButton(onPressed: _onTagScan, child: const Text("Scan Tag"))
          ],
        ),
      ),
    );
  }
}
