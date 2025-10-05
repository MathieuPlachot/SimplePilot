import 'package:flutter/material.dart';
import 'dart:io';

const Color bleuPetrole = Color.fromARGB(255, 36, 221, 83);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
return MaterialApp(
  title: 'UDP Button Sender',
  theme: ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.dark(
      primary: bleuPetrole,
      onPrimary: Colors.white,
      // surface: Colors.grey[900],
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

class ButtonPage extends StatelessWidget {
  ButtonPage({super.key});

// // Listen for incoming messages
//  udpSocket.listen((RawSocketEvent event) {
//  if (event == RawSocketEvent.read) {
//  Datagram datagram = udpSocket.receive();
//  if (datagram != null) {
//  String message = String.fromCharCodes(datagram.data);
//  print('Received message: $message');
//  }
//  }
//  });
// // Send a message

  Future<void> sendUDPMessage(String message) async {
      RawDatagramSocket udpSocket = await RawDatagramSocket.bind('127.0.0.1', 1234);
      print('UDP socket is bound to ${udpSocket.address.address}:${udpSocket.port}');
      udpSocket.send('Hello, UDP!'.codeUnits, InternetAddress('192.168.1.95'), 12346);


    // final sender = await UDP.bind(Endpoint.any());
    // final data = message.codeUnits;
    // await sender.send(
    //   data,
    //   Endpoint.unicast(
    //     InternetAddress.tryParse('192.168.1.95')!,
    //     port: Port(1234),
    //   ),
    // );
    // sender.close();
  }


  ButtonStyle squareButtonStyle = ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.zero, // angles droits
    ),
    padding: EdgeInsets.zero, // pour que le bouton remplisse bien l'espace
  );



Widget buildButtonRow(List<String> labels) {
  return Expanded(
    child: Row(
      children: labels.map((label) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double fontSize = constraints.maxHeight * 0.4; // 40% de la hauteur
                return SizedBox.expand(
                  child: ElevatedButton(
                    style: squareButtonStyle,
                    onPressed: () => sendUDPMessage(label),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
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
      // appBar: AppBar(title: const Text('UDP Button Sender')),
      body: Column(
        children: [
          // Ligne 1 : Label
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double fontSize = constraints.maxHeight * 0.4; // 40% de la hauteur
                  return Center(
                    child: Text(
                      'Mode de contrôle',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Ligne 2 : AUTO et MANU
          buildButtonRow(['AUTO', 'MANU']),
          // Ligne 3 : SET
          buildButtonRow(['SET']),
          // Ligne 4 : <<< et >>>
          buildButtonRow(['<<<', '>>>']),
        ],
      ),
    );
  }
}