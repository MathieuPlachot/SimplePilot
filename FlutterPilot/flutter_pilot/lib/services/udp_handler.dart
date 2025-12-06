import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class UDPHandler extends ChangeNotifier {
  String _serverIpAddress = '127.0.0.1'; // '10.3.141.1';
  int _serverPort = 50002;
  int _listenPort = 0;
  int _pollingRate = 500; // every 500ms
  Timer? _timer;
  RawDatagramSocket? _socket;
  Map<String, dynamic>? _data;
  Map<String, dynamic>? get data => _data;

  UDPHandler() {
    openSocket();
  }

  @override
  void dispose() {
    _timer?.cancel();
    closeSocket();
    super.dispose();
  }

  Future<void> openSocket() async {
    // Avoid binding twice
    if (_socket != null) {
      print('UDP already listening');
      return;
    }

    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _listenPort,
    );
    print('UDP socket listening on port $_listenPort');

    listenIncomingUDP();
  }

  Future<void> listenIncomingUDP() async {
    print('listenIncomingUDP');

    _socket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = _socket!.receive();
        if (datagram != null) {
          String message = String.fromCharCodes(datagram.data);
          print('Received incoming UDP: $message');
          _data = json.decode(message);
          notifyListeners(); // notify widgets to rebuild
        }
      }
    });
  }

  void closeSocket() {
    if (_socket != null) {
      print("Closing UDP socket");
      _socket!.close();
      _socket = null;
    }
  }

  void startPolling() {
    print("Started polling");
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _pollingRate), (_) {
      final Map<String, String> commandJson = {"COMMAND": "REFRESH"};
      sendCommand(commandJson);
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    print("Stopped polling");
  }

  Future<void> sendUDPMessage(String key) async {
    Map<String, Map<String, dynamic>> commands = {
      'AUTO': {'COMMAND': 'SET_MODE', 'MODE': 'AUTO'},
      'MANU': {'COMMAND': 'SET_MODE', 'MODE': 'MANU'},
      '<<<': {
        "AUTO": {'COMMAND': 'DECREASE_SETPOINT', 'VALUE': 10},
        "MANU": {'COMMAND': 'DECREASE_TILLER', 'DURATION': 0.5},
      },
      '>>>': {
        "AUTO": {'COMMAND': 'INCREASE_SETPOINT', 'VALUE': 10},
        "MANU": {'COMMAND': 'INCREASE_TILLER', 'DURATION': 0.5},
      },
    };

    String currentMode = _data != null ? _data!["MODE"] : "";
    print("Current mode: $currentMode");

    Map<String, dynamic> command = commands[key]?['COMMAND'] != null
        ? commands[key]
        : commands[key]?[currentMode];

    sendCommand(command);
  }

  Future<void> sendCommand(Map<String, dynamic> commandJson) async {
    if (_socket == null) {
      print('Socket not initialized');
      return;
    }

    InternetAddress server = InternetAddress(_serverIpAddress);
    final List<int> data = json.encode(commandJson).codeUnits;
    _socket!.send(data, server, _serverPort);
  }
}
