import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class UDPHandler extends ChangeNotifier {
  String _serverIpAddress = '127.0.0.1'; // '10.3.141.1';
  int _serverPort = 1234;
  int _pollingRate = 500; // every 500ms
  Timer? _timer;
  RawDatagramSocket? _incomingSocket;
  RawDatagramSocket? _outgoingSocket;
  Map<String, dynamic>? _data;
  Map<String, dynamic>? get data => _data;

  UDPHandler() {
    openIncomingSocket();
    openOutgoingSocket();
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

  @override
  void dispose() {
    _timer?.cancel();
    closeOutgoingSocket();
    closeIncomingSocket();
    super.dispose();
  }

  void closeIncomingSocket() {
    if (_incomingSocket != null) {
      print("Closing incoming UDP socket");
      _incomingSocket!.close();
      _incomingSocket = null;
    }
  }

  void closeOutgoingSocket() {
    if (_outgoingSocket != null) {
      print("Closing outgoing UDP socket");
      _outgoingSocket!.close();
      _outgoingSocket = null;
    }
  }

  Future<void> openOutgoingSocket() async {
    // Avoid binding twice
    if (_outgoingSocket != null) {
      print('Outgoing UDP already listening');
      return;
    }

    _outgoingSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  }

  Future<void> openIncomingSocket() async {
    // Avoid binding twice
    if (_incomingSocket != null) {
      print('Incoming UDP already listening');
      return;
    }

    _incomingSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      5678,
    );

    listenIncomingUDP();
  }

  Future<void> listenIncomingUDP() async {
    print('listenIncomingUDP');

    _incomingSocket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = _incomingSocket!.receive();
        if (datagram != null) {
          String message = String.fromCharCodes(datagram.data);
          print('Received incoming UDP: $message');
          _data = json.decode(message);
          notifyListeners(); // notify widgets to rebuild
        }
      }
    });
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
    InternetAddress server = InternetAddress(_serverIpAddress);
    final List<int> data = json.encode(commandJson).codeUnits;
    _outgoingSocket!.send(data, server, _serverPort);
  }
}
