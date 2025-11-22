import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

// notifyListeners(); // notify widgets to rebuild

class UDPHandler extends ChangeNotifier {
  bool _foreground = true;
  String _serverIpAddress = '127.0.0.1'; // '10.3.141.1';
  int _serverPort = 1234;
  int _pollingRate = 500; // every 500ms

  Function(String)? onUpdate;

  void setForeground(bool value) {
    _foreground = value;
  }

  void setUpdateCallback(Function(String) callback) {
    onUpdate = callback;
  }

  Future<void> requestPeriodicRefresh() async {
    RawDatagramSocket socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
    );
    String message = '\x06';
    List<int> data = message.codeUnits;
    InternetAddress server = InternetAddress(_serverIpAddress);

    while (_foreground) {
      socket.send(data, server, _serverPort);
      await Future.delayed(Duration(milliseconds: _pollingRate));
    }
  }

  Future<void> listenIncomingUDP() async {
    RawDatagramSocket socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      5678,
    );
    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = socket.receive();
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
    Map<String, String> messages = {
      'AUTO': '\x01',
      'MANU': '\x02',
      'SET HEADING': '\x05',
      '<<<': '\x03',
      '>>>': '\x04',
    };

    String message = messages[label] ?? '';
    RawDatagramSocket socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
    );
    List<int> data = message.codeUnits;
    InternetAddress server = InternetAddress(_serverIpAddress);

    socket.send(data, server, _serverPort);
  }

  Future<void> sendCommand(Map<String, dynamic> commandJson) async {
    RawDatagramSocket socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
    );
    InternetAddress server = InternetAddress(_serverIpAddress);
    final List<int> data = json.encode(commandJson).codeUnits;
    socket.send(data, server, _serverPort);
  }
}
