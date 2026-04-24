import 'package:flutter/material.dart';

class ServoControl extends StatelessWidget {
  final int servoAngle;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const ServoControl({
    super.key,
    required this.servoAngle,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: Colors.orange),
              const SizedBox(width: 10),
              const Text(
                'Control de Mandíbula',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '$servoAngle°',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Slider(
            value: servoAngle.toDouble(),
            min: 0,
            max: 180,
            divisions: 180,
            activeColor: Colors.orange,
            inactiveColor: Colors.white24,
            onChanged: enabled ? onChanged : null,
          ),
          const SizedBox(height: 4),
          Text(
            enabled
                ? 'Mueve el slider para abrir/cerrar la mandíbula física.'
                : 'Conéctate para poder controlar el servo.',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
