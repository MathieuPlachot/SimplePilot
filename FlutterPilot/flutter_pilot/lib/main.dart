import 'package:flutter/material.dart';
import 'package:flutter_pilot/udp_handler.dart';
import 'package:flutter_pilot/first_screen.dart';


const Color bleuPetrole = Color.fromARGB(255, 255, 255, 255);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimplePilot Remote',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
        colorScheme: ColorScheme.dark(
          primary: const Color.fromARGB(255, 255, 255, 255),
          onPrimary: Colors.white,
          onSurface: const Color.fromARGB(255, 249, 250, 252),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 56, 78, 107),
            foregroundColor: const Color.fromARGB(255, 252, 253, 254),
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
      home: FirstPage(),
    );
  }
}

// ToDo
// Show connection status as a top bar
// Send and display Kp,Ki,Kd, IP Addr
// Improve info display




