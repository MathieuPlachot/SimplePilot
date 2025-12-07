import 'package:flutter/material.dart';
import 'package:flutter_pilot/services/udp_handler.dart';
import 'package:flutter_pilot/widgets/connection_status.dart';
import 'package:flutter_pilot/widgets/gps_status.dart';
import 'package:flutter_pilot/widgets/readonly_floating_input.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final UDPHandler udpHandler;
  final ButtonStyle squareButtonStyle = ElevatedButton.styleFrom(
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    padding: EdgeInsets.zero,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      udpHandler = context.read<UDPHandler>();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget setHeadingButton(double fontSize) {
    return ElevatedButton(
      style: squareButtonStyle,
      onPressed: () => sendSetHeadingCommand(),
      child: Text(
        "SET HEADING",
        softWrap: false,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }

  void sendSetHeadingCommand() {
    final Map<String, String> commandJson = {"COMMAND": "SET"};
    udpHandler.sendCommand(commandJson);
  }

  Widget buildButtonRowFromButtons(List<Widget> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox.expand(child: button);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget pilotCommandButton(String label, double fontSize) {
    return ElevatedButton(
      style: squareButtonStyle,
      onPressed: () => udpHandler.sendUDPMessage(label),
      child: Text(
        label,
        softWrap: false,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildButtonRowFromLabels(List<String> labels) {
    return Expanded(
      child: Row(
        children: labels.map((label) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double fontSize = constraints.maxHeight * 0.2;
                  return SizedBox.expand(
                    child: pilotCommandButton(label, fontSize),
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
      body: Column(
        children: [
          SizedBox(height: 16),
          Row(
            children: [
              SizedBox(width: 16),
              Expanded(
                child: ReadonlyFloatingInput(label: "Mode", dataKey: "MODE"),
              ),
              SizedBox(width: 16),
              Expanded(child: ConnectionStatusWidget()),
              SizedBox(width: 16),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              SizedBox(width: 16),
              Expanded(child: GpsStatusWidget()),
              SizedBox(width: 16),
              Expanded(
                child: ReadonlyFloatingInput(
                  label: "Speed",
                  dataKey: "SPEED",
                  suffix: " kts",
                ),
              ),
              SizedBox(width: 16),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              SizedBox(width: 16),
              Expanded(
                child: ReadonlyFloatingInput(
                  label: "Set",
                  dataKey: "SETPOINT",
                  suffix: "°",
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ReadonlyFloatingInput(
                  label: "Current",
                  dataKey: "CURRENT",
                  suffix: "°",
                ),
              ),
              SizedBox(width: 16),
            ],
          ),
          SizedBox(height: 16),
          buildButtonRowFromLabels(['AUTO', 'MANU']),
          buildButtonRowFromButtons([setHeadingButton(20)]),
          buildButtonRowFromLabels(['<<<', '>>>']),
        ],
      ),
    );
  }
}
