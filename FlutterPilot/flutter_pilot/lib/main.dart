import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

const Color bleuPetrole = Color.fromARGB(255, 36, 221, 83);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isInForeground = true;
  final UDPHandler myUDPHandler = UDPHandler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    myUDPHandler.requestPeriodicRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isInForeground = state == AppLifecycleState.resumed;
    myUDPHandler.setForeground(_isInForeground);
    if (_isInForeground) {
      myUDPHandler.requestPeriodicRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UDP Button Sender',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: bleuPetrole,
          onPrimary: Colors.white,
          onSurface: bleuPetrole,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[850],
            foregroundColor: bleuPetrole,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: bleuPetrole),
          bodyMedium: TextStyle(color: bleuPetrole),
          titleLarge: TextStyle(color: bleuPetrole),
        ),
      ),
      home: ButtonPage(),
    );
  }
}

class ButtonPage extends StatefulWidget {
  const ButtonPage({super.key});

  @override
  State<ButtonPage> createState() => _ButtonPageState();
}

class _ButtonPageState extends State<ButtonPage> {
  final UDPHandler myUDPHandler = UDPHandler();
  final ButtonStyle squareButtonStyle = ElevatedButton.styleFrom(
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    padding: EdgeInsets.zero,
  );

  List<String> statusLabels1 = ["MODE:", "GPS:", "LNK:"];
  List<String> statusValues1 = ["UNK", "UNK", "UNK"];
  List<String> statusLabels2 = ["SET:", "CURRENT:"];
  List<String> statusValues2 = ["UNK", "UNK"];

  @override
  void initState() {
    super.initState();
    myUDPHandler.setUpdateCallback(updateStatus);
    myUDPHandler.listenIncomingUDP();
  }

  void updateStatus(String message) {
    setState(() {
      print(message);
      final pilotStatusJson = json.decode(message);
      statusValues1 = [pilotStatusJson["MODE"], pilotStatusJson["GPSSTATE"], pilotStatusJson["LNK"].toString()];
      statusValues2 = [pilotStatusJson["SETPOINT"].toString(), pilotStatusJson["CURRENT"].toString()];
    });
  }

  Widget buildTextRow(List<String> labels, List<String> values) {
    return Expanded(
      child: Row(
        children: List.generate(labels.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double fontSize = constraints.maxHeight * 0.2;
                  return SizedBox.expand(
                    child: Text(
                      '${labels[index]}\n${values[index]}',
                      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget buildButtonRow(List<String> labels) {
    return Expanded(
      child: Row(
        children: labels.map((label) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double fontSize = constraints.maxHeight * 0.2;
                  return SizedBox.expand(
                    child: ElevatedButton(
                      style: squareButtonStyle,
                      onPressed: () => myUDPHandler.sendUDPMessage(label),
                      child: Text(
                        label,
                        softWrap: false,
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Column(
        children: [
          buildTextRow(statusLabels1, statusValues1),
          buildTextRow(statusLabels2, statusValues2),
          buildButtonRow(['AUTO', 'MANU']),
          buildButtonRow(['SET']),
          buildButtonRow(['<<<', '>>>']),
        ],
      ),
    );
  }
}

class UDPHandler {
  bool foreground = true;
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
    var server = InternetAddress('192.168.1.95');
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
      'SET': '\x05',
      '<<<': '\x03',
      '>>>': '\x04',
    };

    var message = messages[label] ?? '';
    var socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    var data = message.codeUnits;
    var server = InternetAddress('192.168.1.95');
    var port = 1234;

    socket.send(data, server, port);
  }
}

class PilotStatus {
  final int setPoint;
  final int current;
  final String gpsState;
  final String mode;

  PilotStatus({required this.setPoint, required this.current, required this.gpsState, required this.mode});

  // Factory pour convertir un objet JSON en instance de User
  factory PilotStatus.fromJson(Map json) {
    return PilotStatus(
      setPoint: json['SETPOINT'],
      current: json['CURRENT'],
      gpsState: json['GPSSTATE'],
      mode: json['MODE'],
    );
  }
}