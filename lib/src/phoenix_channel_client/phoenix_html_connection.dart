// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:app/src/phoenix_channel_client/phoenix_connection.dart';

class PhoenixHtmlConnection extends PhoenixConnection {
  final String _endpoint;

  late WebSocket _conn;
  late Future _opened;

  @override
  bool get isConnected => _conn.readyState == WebSocket.OPEN;
  @override
  int get readyState => _conn.readyState;

  static PhoenixConnection provider(String endpoint) {
    return PhoenixHtmlConnection(endpoint);
  }

  PhoenixHtmlConnection(this._endpoint) {
    _conn = WebSocket(_endpoint);
    _opened = _conn.onOpen.first;
  }

  // waitForConnection is idempotent, it can be called many
  // times before or after the connection is established
  @override
  Future<PhoenixConnection> waitForConnection() async {
    if (_conn.readyState == WebSocket.OPEN) {
      return this;
    }

    await _opened;
    return this;
  }

  @override
  void close([int? code, String? reason]) => _conn.close(code, reason);

  @override
  void send(String data) => _conn.sendString(data);

  @override
  void onClose(Function() callback) => _conn.onClose.listen((e) {
        callback();
      });

  @override
  void onError(Function(dynamic) callback) => _conn.onError.listen((e) {
        callback(e);
      });

  @override
  void onMessage(Function(String m) callback) => _conn.onMessage.listen((e) {
        callback(_messageToString(e));
      });

  String _messageToString(MessageEvent e) {
    return e.data as String;
  }
}
