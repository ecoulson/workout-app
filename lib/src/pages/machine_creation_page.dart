import 'dart:convert';
import 'dart:io';

import 'package:app/src/pages/scan_tag_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../models/machine.dart';

class MachineCreationPage extends StatefulWidget {
  const MachineCreationPage({super.key});

  @override
  State<MachineCreationPage> createState() => _MachineCreationPageState();
}

class _MachineCreationPageState extends State<MachineCreationPage> {
  TextEditingController textEditingController = TextEditingController();
  String _type = "";

  void _onTypeChange(String type) {
    setState(() {
      _type = type;
    });
  }

  void _createMachineTag() async {
    var url = Uri.http('localhost:4000', 'api/workouts/machines');
    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: "application/json",
    };
    Map<String, dynamic> data = {
      "machine": {
        'type': _type,
        "brand": "Lifetime Fitness",
      }
    };
    Response response =
        await http.post(url, headers: headers, body: jsonEncode(data));
    Machine machine = Machine.fromJson(jsonDecode(response.body)["data"]);
    String link =
        'workouts://repcounter.com/repititions?machineId=${machine.id}';

    if (!await NfcManager.instance.isAvailable()) {
      return;
    }
    NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) =>
            _handleDiscoveredTag(tag, link, Navigator.of(context)));
    // create screen for scanning tags
    // ability to navigate to page to create tags
    // on tag scan connect to correct channel via machine id
    // this screen is new home screen
  }

  Future<void> _handleDiscoveredTag(
      NfcTag tag, String link, NavigatorState navigatorState) async {
    try {
      await _writeTag(tag, link, navigatorState);
    } catch (error) {
      NfcManager.instance.stopSession(errorMessage: "Failed to write tag");
    }
  }

  Future<void> _writeTag(
      NfcTag tag, String link, NavigatorState navigatorState) async {
    Ndef? ndefTag = Ndef.from(tag);
    if (ndefTag == null) {
      NfcManager.instance.stopSession(errorMessage: "Tag was not an NDEF tag");
      return;
    }
    if (!ndefTag.isWritable) {
      NfcManager.instance.stopSession(errorMessage: "Tag is not writable");
      return;
    }
    NdefMessage message = NdefMessage([NdefRecord.createText(link)]);
    await ndefTag.write(message);
    NfcManager.instance.stopSession();
    navigatorState
        .push(MaterialPageRoute(builder: (context) => const ScanTagPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tag Machine"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Create Machine Tag:',
                ),
                TextField(
                  onSubmitted: _onTypeChange,
                  controller: textEditingController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Machine Type",
                  ),
                ),
                ElevatedButton(
                    onPressed: _createMachineTag,
                    child: const Text("Create Tag"))
              ],
            )
          ],
        ),
      ),
    );
  }
}
