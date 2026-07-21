import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pilot/models/connection_status.model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_iot/wifi_iot.dart';

class UDPHandler extends ChangeNotifier {
  static const String _serverIpAddressPrefKey = 'server_ip_address';
  static const String _autoStepPrefKey = 'auto_step';
  static const String _manuDurationPrefKey = 'manu_duration';
  static const String _manuSpeedPrefKey = 'manu_speed';

  String _serverIpAddress = '127.0.0.1'; // '10.3.141.1';
  int _autoStep = 10;
  double _manuDuration = 0.5;
  int _manuSpeed = 50;
  double _forcedKp = 0;
  double _forcedKd = 0;
  double _forcedKi = 0;
  int _serverPort = 50002;
  int _listenPort = 0;
  int _pollingRate = 500; // every 500ms
  Timer? _pollingTimer;
  RawDatagramSocket? _socket;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  Map<String, dynamic>? _data;
  Duration _connectionThreshold = Duration(seconds: 3);
  Timer? _timeoutTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  ConnectionStatus get connectionStatus => _connectionStatus;
  Map<String, dynamic>? get data => _data;
  String get serverIpAddress => _serverIpAddress;
  int get autoStep => _autoStep;
  double get manuDuration => _manuDuration;
  int get manuSpeed => _manuSpeed;

  UDPHandler() {
    _loadServerIpAddress();
    _loadAutoStep();
    _loadManuDuration();
    _loadManuSpeed();
    openSocket();
    _listenConnectivityChanges();
  }

  void _listenConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      if (results.contains(ConnectivityResult.wifi)) {
        print('Wi-Fi reconnected, re-binding process to network');
        await WiFiForIoTPlugin.forceWifiUsage(true);
      }
    });
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

  Future<void> _loadAutoStep() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAutoStep = prefs.getInt(_autoStepPrefKey);
    if (savedAutoStep != null) {
      _autoStep = savedAutoStep;
      notifyListeners();
    }
  }

  Future<void> setAutoStep(int step) async {
    _autoStep = step;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoStepPrefKey, step);
  }

  Future<void> _loadManuDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final savedManuDuration = prefs.getDouble(_manuDurationPrefKey);
    if (savedManuDuration != null) {
      _manuDuration = savedManuDuration;
      notifyListeners();
    }
  }

  Future<void> setManuDuration(double duration) async {
    _manuDuration = duration;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_manuDurationPrefKey, duration);
  }

  Future<void> _loadManuSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final savedManuSpeed = prefs.getInt(_manuSpeedPrefKey);
    if (savedManuSpeed != null) {
      _manuSpeed = savedManuSpeed;
      notifyListeners();
    }
  }

  Future<void> setManuSpeed(int speed) async {
    _manuSpeed = speed;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_manuSpeedPrefKey, speed);
  }

  void setForcedCoefficients(double kp, double kd, double ki) {
    _forcedKp = kp;
    _forcedKd = kd;
    _forcedKi = ki;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
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

    // ControlUnit has no internet access, so if mobile data is enabled
    // Android/iOS may route our traffic over cellular instead of Wi-Fi.
    // Force the app's traffic onto Wi-Fi without disabling mobile data.
    await WiFiForIoTPlugin.forceWifiUsage(true);

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
      WiFiForIoTPlugin.forceWifiUsage(false);
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
      'FORCE_COEFFS': {
        'COMMAND': 'FORCE_COEFFS',
        'VALUES': '$_forcedKp,$_forcedKi,$_forcedKd',
      },
      'left': {
        "AUTO": {'COMMAND': 'DECREASE_SETPOINT', 'VALUE': _autoStep},
        "MANU": {
          'COMMAND': 'DECREASE_TILLER',
          'DURATION': _manuDuration,
          'SPEED': _manuSpeed,
        },
      },
      'right': {
        "AUTO": {'COMMAND': 'INCREASE_SETPOINT', 'VALUE': _autoStep},
        "MANU": {
          'COMMAND': 'INCREASE_TILLER',
          'DURATION': _manuDuration,
          'SPEED': _manuSpeed,
        },
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
