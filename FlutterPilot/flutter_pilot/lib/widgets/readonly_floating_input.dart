import 'package:flutter/material.dart';
import 'package:flutter_pilot/services/udp_handler.dart';
import 'package:provider/provider.dart';

class ReadonlyFloatingInput extends StatelessWidget {
  final String label;
  final String dataKey;
  final String suffix;

  const ReadonlyFloatingInput({
    super.key,
    this.label = "Label",
    this.dataKey = "Key",
    this.suffix = "",
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? data = context.watch<UDPHandler>().data;

    String textValue = "-";

    if (data != null) {
      dynamic value = data[dataKey];
      if (value is num) {
        value = value.round(); // rounds to nearest integer
      }
      textValue = value.toString() + suffix;
    }

    return TextField(
      controller: TextEditingController(text: textValue),
      readOnly: true, // user cannot type but UI looks normal
      enableInteractiveSelection: false,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 12.0,
        ),
      ),
    );
  }
}
