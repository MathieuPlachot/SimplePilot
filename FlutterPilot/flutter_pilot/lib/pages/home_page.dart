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
  String selected = "MANU";
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

  @override
  Widget build(BuildContext context) {
    final String? polledMode = context.watch<UDPHandler>().data?["MODE"];

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
          Spacer(),
          SizedBox(height: 16),
          Row(
            children: [
              SizedBox(width: 16),
              Expanded(
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: "MANU", label: Text("Manu")),
                    ButtonSegment(value: "AUTO", label: Text("Auto")),
                    ButtonSegment(value: "WAYPOINT", label: Text("Waypoint")),
                  ],
                  selected: {selected},

                  // Callback
                  onSelectionChanged: (Set<String> newValue) {
                    setState(() => selected = newValue.first);
                    udpHandler.sendUDPMessage(newValue.first);
                  },
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
                child: OutlinedButton.icon(
                  icon: Icon(Icons.explore),
                  label: Text('Set heading'),
                  onPressed: () => udpHandler.sendUDPMessage('SET'),
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
                child: OutlinedButton.icon(
                  icon: Icon(polledMode == "AUTO" ? Icons.remove : Icons.arrow_back),
                  label: Text(polledMode == "AUTO" ? '10°' : 'Left'),
                  onPressed: () {
                    print('Left $selected');
                    udpHandler.sendUDPMessage('left');
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(polledMode == "AUTO" ? Icons.add : Icons.arrow_forward),
                  iconAlignment:
                      polledMode == "AUTO" ? IconAlignment.start : IconAlignment.end,
                  label: Text(polledMode == "AUTO" ? '10°' : 'Right'),
                  onPressed: () {
                    print('Right $selected');
                    udpHandler.sendUDPMessage('right');
                  },
                ),
              ),
              SizedBox(width: 16),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
