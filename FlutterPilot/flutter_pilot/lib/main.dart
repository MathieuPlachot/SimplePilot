import 'package:flutter/material.dart';
import 'package:flutter_pilot/pages/about_page.dart';
import 'package:flutter_pilot/pages/home_shell.dart';
import 'package:flutter_pilot/services/udp_handler.dart';
import 'package:flutter_pilot/styles/app_themes.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => UDPHandler(), child: SimplePilot()),
  );
}

class SimplePilot extends StatelessWidget {
  const SimplePilot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: HomeShell(),
      routes: {'/about': (_) => AboutPage()},
    );
  }
}

// TODO:
// * Continuous movement in manual mode
// * Rework UI to allow the definition of coefficients per speed
// * Rework first screen UI to add waypoint mode (mode selector, current waypoint info, route selection  ...)
// * WiFi disco issue TO VALIDATE
