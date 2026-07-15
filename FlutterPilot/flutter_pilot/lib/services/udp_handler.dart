import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pilot/models/connection_status.model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UDPHandler extends ChangeNotifier {
  static const String _serverIpAddressPrefKey = 'server_ip_address';

  String _serverIpAddress = '127.0.0.1'; // '10.3.141.1';
  int _serverPort = 50002;
  int _listenPort = 0;
  int _pollingRate = 500; // every 500ms
  Timer? _pollingTimer;
  RawDatagramSocket? _socket;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  Map<String, dynamic>? _data;
  Duration _connectionThreshold = Duration(seconds: 3);
  Timer? _timeoutTimer;

  ConnectionStatus get connectionStatus => _connectionStatus;
  Map<String, dynamic>? get data => _data;
  String get serverIpAddress => _serverIpAddress;

  UDPHandler() {
    _loadServerIpAddress();
    openSocket();
  }

  Future<void> _loadServerIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIpAddress = prefs.getString(_serverIpAddressPrefKey);
    if (savedIpAddress != null && savedIpAddress.isNotEmpty) {
      _serverIpAddress = savedIpAddress;
      notifyListeners();
    }
  }

  Future<void> setServerIpAddress(String ipAddress) async {
    _serverIpAddress = ipAddress;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverIpAddressPrefKey, ipAddress);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _timeoutTimer?.cancel();
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
          _handleIncomingMessage();
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
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(milliseconds: _pollingRate), (_) {
      final Map<String, String> commandJson = {"COMMAND": "REFRESH"};
      sendCommand(commandJson);
    });
  }

  void stopPolling() {
    _updateConnectionStatus(ConnectionStatus.disconnected);
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print("Stopped polling");
  }

  Future<void> sendUDPMessage(String key) async {
    Map<String, Map<String, dynamic>> commands = {
      'SET': {"COMMAND": "SET"},
      'AUTO': {'COMMAND': 'SET_MODE', 'MODE': 'AUTO'},
      'MANU': {'COMMAND': 'SET_MODE', 'MODE': 'MANU'},
      'left': {
        "AUTO": {'COMMAND': 'DECREASE_SETPOINT', 'VALUE': 10},
        "MANU": {'COMMAND': 'DECREASE_TILLER', 'DURATION': 0.5},
      },
      'right': {
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
    print(
      'Sending UDP command to $_serverIpAddress:$_serverPort -> $commandJson',
    );
    _socket!.send(data, server, _serverPort);

    // Only arm the watchdog if one isn't already pending. It must only be
    // reset when a response actually arrives (_handleIncomingMessage) -
    // resetting it on every send would keep pushing it out on each poll
    // tick (500ms) and it would never get a chance to fire at 3s.
    _timeoutTimer ??= Timer(_connectionThreshold, () {
      _updateConnectionStatus(ConnectionStatus.disconnected);
      _timeoutTimer = null;
    });
  }

  void _handleIncomingMessage() {
    // A response came in → cancel the watchdog and mark connected. The next
    // sendCommand call will arm a fresh watchdog for the next response.
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _updateConnectionStatus(ConnectionStatus.connected);
  }

  void _updateConnectionStatus(ConnectionStatus newStatus) {
    if (newStatus != _connectionStatus) {
      _connectionStatus = newStatus;
      notifyListeners();
    }
  }
}
