import 'dart:developer';
import 'dart:io';
import 'dart:async';

import 'package:app/src/phoenix_channel_client/phoenix_connection.dart';

class PhoenixIoConnection extends PhoenixConnection {
  Future<WebSocket>? _connFuture;
  WebSocket? _conn;
  final String _endpoint;

  // Use completer for close event because:
  //  * onDone of WebSocket doesn't fire consistently :(
  //  * this enables setting onClose/onDone/onError separately
  final Completer _closed = Completer();

  @override
  bool get isConnected => _conn?.readyState == WebSocket.open;
  @override
  int get readyState => _conn?.readyState ?? WebSocket.closed;

  static PhoenixConnection provider(String endpoint) {
    return PhoenixIoConnection(endpoint);
  }

  PhoenixIoConnection(this._endpoint);

  // waitForConnection is idempotent, it can be called many
  // times before or after the connection is established
  @override
  Future<PhoenixConnection> waitForConnection() async {
    _connFuture ??= WebSocket.connect(_endpoint);
    _conn = await _connFuture;

    return this;
  }

  @override
  void close([int? code, String? reason]) => _conn?.close(code, reason);

  @override
  void send(String data) {
    if (isConnected) {
      try {
        _conn!.add(data);
      } catch (e) {
        log((e as dynamic).message);
      }
    }
  }

  @override
  void onClose(Function() callback) {
    _closed.future.then((e) {
      callback();
    });
  }

  @override
  void onError(Function(dynamic) callback) {
    _conn!.handleError(callback);
    _conn!.done.catchError(callback);
  }

  String? _messageToString(dynamic e) {
    return e as String?;
  }

  void onMessage(Function(String? m) callback) {
    _conn!.listen((e) {
      callback(_messageToString(e));
    }, onDone: () {
      _closed.complete();
    });
  }
}
