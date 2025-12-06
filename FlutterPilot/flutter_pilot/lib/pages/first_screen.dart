import 'package:flutter/material.dart';
import 'package:flutter_pilot/services/udp_handler.dart';
import 'package:provider/provider.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> with WidgetsBindingObserver {
  late final UDPHandler udpHandler;
  final ButtonStyle squareButtonStyle = ElevatedButton.styleFrom(
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    padding: EdgeInsets.zero,
  );

  List<String> statusLabels1 = ["MODE:", "GPS:", "LNK:"];
  List<String> statusLabels2 = ["SET:", "CURRENT:", "SPEED:"];

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

  Widget paramAndValueText(
    String paramName,
    String paramValue,
    double fontSize,
  ) {
    return Text(
      '$paramName\n$paramValue',
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
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
                  double fontSize = constraints.maxHeight * 0.18;
                  return SizedBox.expand(
                    child: paramAndValueText(
                      labels[index],
                      values[index],
                      fontSize,
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
    final json = context.watch<UDPHandler>().data;
    List<String> values1;
    List<String> values2;

    if (json == null) {
      values1 = ["UNK", "UNK", "UNK"];
      values2 = ["UNK", "UNK", "UNK"];
    } else {
      values1 = [json["MODE"], json["GPSSTATE"], json["LNK"].toString()];
      values2 = [
        json["SETPOINT"].toString(),
        json["CURRENT"].toString(),
        json["SPEED"].toString(),
      ];
    }

    return Scaffold(
      body: Column(
        children: [
          buildTextRow(statusLabels1, values1),
          buildTextRow(statusLabels2, values2),
          buildButtonRowFromLabels(['AUTO', 'MANU']),
          buildButtonRowFromButtons([setHeadingButton(20)]),
          buildButtonRowFromLabels(['<<<', '>>>']),
        ],
      ),
    );
  }
}
