import 'package:flutter/material.dart';
import 'package:flutter_pilot/widgets/pid_contribution_chart.dart';
// import 'package:flutter_pilot/widgets/readonly_floating_input.dart';

class TuningPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: PidContributionChart(),
        // child: Column(
        //   children: [
        //     SizedBox(height: 16),
        //     Row(
        //       children: [
        //         SizedBox(width: 16),
        //         Expanded(
        //           child: ReadonlyFloatingInput(label: "C", dataKey: "C"),
        //         ),
        //         SizedBox(width: 16),
        //       ],
        //     ),
        //     SizedBox(height: 16),
        //     Row(
        //       children: [
        //         SizedBox(width: 16),
        //         Expanded(
        //           child: ReadonlyFloatingInput(label: "CP", dataKey: "CP"),
        //         ),
        //         SizedBox(width: 16),
        //         Expanded(
        //           child: ReadonlyFloatingInput(label: "CD", dataKey: "CD"),
        //         ),
        //         SizedBox(width: 16),
        //         Expanded(
        //           child: ReadonlyFloatingInput(label: "Ci", dataKey: "Ci"),
        //         ),
        //         SizedBox(width: 16),
        //       ],
        //     ),
        //   ],
        // ),
      ),
    );
  }
}
