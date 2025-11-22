import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> parametersList = [
    'Server IP',
    'Kp (Proportional Coefficient)',
    'Ki (Integral Coefficient)',
    'Kd (Derivative Coefficient)',
  ];

  final List<TextEditingController> _controllers = List.generate(
    10,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    for (TextEditingController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildLabeledTextField(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(parametersList[index])),
          SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: TextField(
              controller: _controllers[index],
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
            child: ListView.builder(
              itemCount: parametersList.length,
              itemBuilder: (context, index) => _buildLabeledTextField(index),
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
                    onPressed: () {
                      // Handle second button press
                    },
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
