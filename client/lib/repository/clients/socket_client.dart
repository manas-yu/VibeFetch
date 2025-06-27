import 'package:client/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketClient {
  io.Socket? socket;
  static SocketClient? _instance;

  SocketClient._internal() {
    socket = io.io(host, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket!.connect();
    print('Connecting to socket at $host');
    socket!.onConnect((_) => print('connected'));
    socket!.onDisconnect((data) => print('disconnected'));
    socket!.onError((err) => print('socket error: $err'));
  }

  static SocketClient get instance {
    _instance ??= SocketClient._internal();
    return _instance!;
  }
}
