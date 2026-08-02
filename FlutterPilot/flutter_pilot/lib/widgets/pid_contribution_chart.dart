import 'package:flutter/material.dart';
import 'package:flutter_pilot/services/udp_handler.dart';
import 'package:flutter_pilot/styles/app_colors.dart';
import 'package:provider/provider.dart';

/// Visualizes how Cp, Cd and Ci each contribute to the resulting command C,
/// as bars diverging left/right from a zero line (PID terms can be negative).
class PidContributionChart extends StatelessWidget {
  const PidContributionChart({super.key});

  double _valueOf(Map<String, dynamic>? data, String key) {
    final dynamic raw = data?[key];
    return raw is num ? raw.toDouble() : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? data = context.watch<UDPHandler>().data;

    final double cp = _valueOf(data, "Cp");
    final double cd = _valueOf(data, "Cd");
    final double ci = _valueOf(data, "Ci");
    final double c = _valueOf(data, "C");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DivergingBarRow(label: "Cp", value: cp),
        SizedBox(height: 12),
        _DivergingBarRow(label: "Cd", value: cd),
        SizedBox(height: 12),
        _DivergingBarRow(label: "Ci", value: ci),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: AppColors.muted, height: 1),
        ),
        _DivergingBarRow(label: "C", value: c, emphasize: true),
      ],
    );
  }
}

class _DivergingBarRow extends StatelessWidget {
  static const double _scaleMax = 100.0;

  final String label;
  final double value;
  final bool emphasize;

  const _DivergingBarRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool overflow = value.abs() > _scaleMax;
    final double fraction = (value.abs() / _scaleMax).clamp(0.0, 1.0);
    final Color color = overflow ? AppColors.danger : AppColors.primary;
    final double barHeight = emphasize ? 22 : 16;

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: barHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double halfWidth = constraints.maxWidth / 2;
                final double barWidth = halfWidth * fraction;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.navbarBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned(
                      left: halfWidth - 0.75,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 1.5, color: AppColors.muted),
                    ),
                    if (barWidth > 0)
                      Positioned(
                        left: value < 0 ? halfWidth - barWidth : halfWidth,
                        top: 0,
                        bottom: 0,
                        width: barWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: overflow ? AppColors.danger : AppColors.textDark,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
