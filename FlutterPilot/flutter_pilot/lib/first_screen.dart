import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_pilot/udp_handler.dart';
import 'package:flutter_pilot/second_screen.dart';


class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
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

  Widget paramAndValueText(String paramName, String paramValue, double fontSize){
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
                  double fontSize = constraints.maxHeight * 0.2;
                  return SizedBox.expand(
                    child: paramAndValueText(labels[index],values[index], fontSize),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget pilotCommandButton(String label, double fontSize){
    return ElevatedButton(
      style: squareButtonStyle,
      onPressed: () => myUDPHandler.sendUDPMessage(label),
      child: Text(
        label,
        softWrap: false,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),)
    );
  }

  Widget buildButtonRow(List<String> labels) {
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

  Widget settingsButton(BuildContext context){
    return Expanded(
      child:
        ElevatedButton(
          style: squareButtonStyle,
          onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => SecondPage()));},
          child: Text(
            "Settings",
            softWrap: false,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),)
        )
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
          settingsButton(context),
        ],
      ),
    );
  }
}