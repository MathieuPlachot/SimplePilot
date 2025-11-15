import 'dart:io';
import 'dart:convert';

class UDPHandler {

  bool foreground = true;
  // String ipAddr = '10.3.141.1';
  String ipAddr = '127.0.0.1';


  Function(String)? onUpdate;

  void setForeground(bool value) {
    foreground = value;
  }

  void setUpdateCallback(Function(String) callback) {
    onUpdate = callback;
  }

  Future<void> requestPeriodicRefresh() async {
    var socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    var message = '\x06';
    var data = message.codeUnits;
    var server = InternetAddress(ipAddr);
    var port = 1234;

    while (foreground) {
      socket.send(data, server, port);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> listenIncomingUDP() async {
    var socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5678);
    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        var datagram = socket.receive();
        if (datagram != null) {
          String message = String.fromCharCodes(datagram.data);
          print(message);
          if (onUpdate != null) {
            onUpdate!(message);
          }
        }
      }
    });
  }

  Future<void> sendUDPMessage(String label) async {
    var messages = {
      'AUTO': '\x01',
      'MANU': '\x02',
      'SET HEADING': '\x05',
      '<<<': '\x03',
      '>>>': '\x04',
    };

    var message = messages[label] ?? '';
    var socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    var data = message.codeUnits;
    var server = InternetAddress(ipAddr);
    var port = 1234;

    socket.send(data, server, port);
  }

  Future<void> sendCommand(Map<String, String> commandJson) async {

    var socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    var server = InternetAddress(ipAddr);
    var port = 1234;

    final data = json.encode(commandJson).codeUnits;
    socket.send(data, server, port);
  }

}