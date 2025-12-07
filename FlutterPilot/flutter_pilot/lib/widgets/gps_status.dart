import 'package:flutter/material.dart';
import 'package:flutter_pilot/services/udp_handler.dart';
import 'package:flutter_pilot/styles/app_colors.dart';
import 'package:provider/provider.dart';

class GpsStatusWidget extends StatelessWidget {
  final double bulletDiameter;

  const GpsStatusWidget({super.key, this.bulletDiameter = 15.0});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<UDPHandler>().data;

    final bool valid = (data != null && data["GPSSTATE"] == "A");

    // Map enum → display text
    final String textValue = valid ? "Valid" : "Invalid";

    // Map enum → bullet color
    final Color bulletColor = valid ? AppColors.success : AppColors.danger;

    return TextField(
      controller: TextEditingController(text: textValue),
      readOnly: true, // user cannot type but UI looks normal
      enableInteractiveSelection: false,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: "GPS",
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),

        // bullet inside the input
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Container(
            width: bulletDiameter,
            height: bulletDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bulletColor,
            ),
          ),
        ),

        // remove default huge icon constraints
        suffixIconConstraints: BoxConstraints(
          minWidth: bulletDiameter,
          minHeight: bulletDiameter,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 12.0,
        ),
      ),
    );
  }
}
