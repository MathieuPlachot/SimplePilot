import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pilot/services/udp_handler.dart';
import 'package:flutter_pilot/styles/app_colors.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _serverIpController = TextEditingController();
  final TextEditingController _autoStepController = TextEditingController();
  final TextEditingController _manuDurationController = TextEditingController();
  final TextEditingController _manuSpeedController = TextEditingController();

  final List<String> parametersList = [
    'Kp (Proportional Coefficient)',
    'Ki (Integral Coefficient)',
    'Kd (Derivative Coefficient)',
  ];

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _serverIpController.text = context.read<UDPHandler>().serverIpAddress;
    _autoStepController.text = context.read<UDPHandler>().autoStep.toString();
    _manuDurationController.text = context
        .read<UDPHandler>()
        .manuDuration
        .toString();
    _manuSpeedController.text = context.read<UDPHandler>().manuSpeed.toString();

    for (final controller in [
      _serverIpController,
      _autoStepController,
      _manuDurationController,
      _manuSpeedController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _serverIpController,
      _autoStepController,
      _manuDurationController,
      _manuSpeedController,
    ]) {
      controller.removeListener(_onFieldChanged);
    }
    _serverIpController.dispose();
    _autoStepController.dispose();
    _manuDurationController.dispose();
    _manuSpeedController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    context.read<UDPHandler>().setServerIpAddress(
      _serverIpController.text.trim(),
    );
    final int? autoStep = int.tryParse(_autoStepController.text.trim());
    if (autoStep != null) {
      context.read<UDPHandler>().setAutoStep(autoStep);
    }
    final double? manuDuration = double.tryParse(
      _manuDurationController.text.trim(),
    );
    if (manuDuration != null) {
      context.read<UDPHandler>().setManuDuration(manuDuration);
    }
    final int? manuSpeed = int.tryParse(_manuSpeedController.text.trim());
    if (manuSpeed != null) {
      context.read<UDPHandler>().setManuSpeed(manuSpeed);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SizedBox(
          height: 40,
          child: Center(child: Text('Settings saved')),
        ),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  void _adjustValue(
    TextEditingController controller,
    double step,
    int decimals,
  ) {
    final double current = double.tryParse(controller.text.trim()) ?? 0;
    final double next = (current + step).clamp(0, double.infinity);
    setState(() {
      controller.text = next.toStringAsFixed(decimals);
    });
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

  bool _isModified(TextEditingController controller, String savedValue) {
    return controller.text.trim() != savedValue;
  }

  Widget _buildLabeledTextField(
    String label,
    TextEditingController controller,
    String savedValue, {
    TextInputType keyboardType = TextInputType.text,
    double? step,
    int decimals = 0,
  }) {
    final bool isModified = _isModified(controller, savedValue);
    final Color borderColor = isModified ? Colors.orange : AppColors.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
          suffixIcon: step == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(24, 18),
                          maximumSize: const Size(24, 18),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        iconSize: 16,
                        icon: const Icon(Icons.arrow_drop_up),
                        onPressed: () =>
                            _adjustValue(controller, step, decimals),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(24, 18),
                          maximumSize: const Size(24, 18),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        iconSize: 16,
                        icon: const Icon(Icons.arrow_drop_down),
                        onPressed: () =>
                            _adjustValue(controller, -step, decimals),
                      ),
                    ],
                  ),
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 40,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final UDPHandler udpHandler = context.watch<UDPHandler>();

    final bool hasChanges =
        _isModified(_serverIpController, udpHandler.serverIpAddress) ||
        _isModified(_autoStepController, udpHandler.autoStep.toString()) ||
        _isModified(
          _manuDurationController,
          udpHandler.manuDuration.toString(),
        ) ||
        _isModified(_manuSpeedController, udpHandler.manuSpeed.toString());

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildSectionDivider('General'),
                _buildLabeledTextField(
                  'Server IP',
                  _serverIpController,
                  udpHandler.serverIpAddress,
                ),
                _buildSectionDivider('Mode: AUTO'),
                _buildLabeledTextField(
                  'Step (degrees)',
                  _autoStepController,
                  udpHandler.autoStep.toString(),
                  keyboardType: TextInputType.number,
                  step: 1,
                ),
                _buildSectionDivider('Mode: MANU'),
                _buildLabeledTextField(
                  'Duration (seconds)',
                  _manuDurationController,
                  udpHandler.manuDuration.toString(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  step: 0.1,
                  decimals: 1,
                ),
                _buildLabeledTextField(
                  'Speed (%)',
                  _manuSpeedController,
                  udpHandler.manuSpeed.toString(),
                  keyboardType: TextInputType.number,
                  step: 1,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Save'),
                    onPressed: hasChanges ? _saveSettings : null,
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
