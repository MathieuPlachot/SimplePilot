import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pilot/services/udp_handler.dart';
import 'package:flutter_pilot/styles/app_colors.dart';
import 'package:flutter_pilot/widgets/pid_contribution_chart.dart';

class TuningPage extends StatefulWidget {
  @override
  State<TuningPage> createState() => _TuningPageState();
}

class _TuningPageState extends State<TuningPage> {
  final TextEditingController _kpController = TextEditingController();
  final TextEditingController _kdController = TextEditingController();
  final TextEditingController _kiController = TextEditingController();

  late final UDPHandler _udpHandler;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _udpHandler = context.read<UDPHandler>();
    _udpHandler.addListener(_onUdpDataChanged);
    _onUdpDataChanged();

    for (final controller in [_kpController, _kdController, _kiController]) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    setState(() {});
  }

  void _onUdpDataChanged() {
    if (_prefilled) return;
    final Map<String, dynamic>? data = _udpHandler.data;
    if (data == null) return;

    setState(() {
      _kpController.text = _formatCoeff(data['KP']);
      _kdController.text = _formatCoeff(data['KD']);
      _kiController.text = _formatCoeff(data['Ki']);
      _prefilled = true;
    });
  }

  String _formatCoeff(dynamic value) {
    return value is num ? value.toString() : '';
  }

  bool _isModified(TextEditingController controller, dynamic currentValue) {
    return controller.text.trim() != _formatCoeff(currentValue);
  }

  void _applyCoefficients() {
    final double kp = double.tryParse(_kpController.text.trim()) ?? 0;
    final double kd = double.tryParse(_kdController.text.trim()) ?? 0;
    final double ki = double.tryParse(_kiController.text.trim()) ?? 0;
    _udpHandler.setForcedCoefficients(kp, kd, ki);
    _udpHandler.sendUDPMessage('FORCE_COEFFS');
  }

  @override
  void dispose() {
    _udpHandler.removeListener(_onUdpDataChanged);
    for (final controller in [_kpController, _kdController, _kiController]) {
      controller.removeListener(_onFieldChanged);
    }
    _kpController.dispose();
    _kdController.dispose();
    _kiController.dispose();
    super.dispose();
  }

  Widget _buildSectionDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        children: [
          SizedBox(width: 16, child: Divider(color: AppColors.muted)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(label, style: TextStyle(color: AppColors.muted)),
          ),
          Expanded(child: Divider(color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildCoefficientField(
    String label,
    TextEditingController controller,
    dynamic currentValue,
  ) {
    final bool isModified = _isModified(controller, currentValue);
    final Color borderColor = isModified ? Colors.orange : AppColors.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 12.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: borderColor, width: 1.4),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: isModified ? Colors.orange : Colors.blueAccent,
                  width: 2,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              'Current value: ${currentValue ?? '-'}',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? data = context.watch<UDPHandler>().data;

    final bool hasChanges =
        _isModified(_kpController, data?['KP']) ||
        _isModified(_kdController, data?['KD']) ||
        _isModified(_kiController, data?['Ki']);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  PidContributionChart(),
                  SizedBox(height: 8),
                  _buildSectionDivider('Coefficients'),
                  _buildCoefficientField('Kp', _kpController, data?['KP']),
                  _buildCoefficientField('Kd', _kdController, data?['KD']),
                  _buildCoefficientField('Ki', _kiController, data?['Ki']),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.input),
                    label: Text('Apply'),
                    onPressed: hasChanges ? _applyCoefficients : null,
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
