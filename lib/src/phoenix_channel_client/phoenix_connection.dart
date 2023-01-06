import 'dart:async';

typedef PhoenixConnectionProvider = Function(String endpoint);

abstract class PhoenixConnection {
  static const closeNormal = 1000;

  bool get isConnected;
  int get readyState;

  Future<PhoenixConnection> waitForConnection();

  void close([int? code, String? reason]);
  void closeNormally([String? reason]) => close(closeNormal, reason);

  void send(String data);

  void onClose(void Function() callback);
  void onError(void Function(dynamic) callback);
  void onMessage(void Function(String?) callback);
}
