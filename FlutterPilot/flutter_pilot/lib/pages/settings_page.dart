import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pilot/services/udp_handler.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _serverIpController = TextEditingController();

  final List<String> parametersList = [
    'Kp (Proportional Coefficient)',
    'Ki (Integral Coefficient)',
    'Kd (Derivative Coefficient)',
  ];

  final List<TextEditingController> _controllers = List.generate(
    10,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    _serverIpController.text = context.read<UDPHandler>().serverIpAddress;
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    for (TextEditingController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveSettings() {
    context.read<UDPHandler>().setServerIpAddress(
      _serverIpController.text.trim(),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Settings saved')));
  }

  Widget _buildLabeledTextField(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter value',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildLabeledTextField('Server IP', _serverIpController),
                for (int i = 0; i < parametersList.length; i++)
                  _buildLabeledTextField(parametersList[i], _controllers[i]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle first button press
                    },
                    child: Text('Test'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    child: Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
