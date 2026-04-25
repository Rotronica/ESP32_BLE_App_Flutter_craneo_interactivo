// Archivo: servo_control.dart
// Descripción: Widget para controlar el ángulo de apertura de la mandíbula del cráneo.
// Incluye un slider que permite ajustar el ángulo del servo motor entre 0° y 35°.
// Se deshabilita cuando no hay conexión Bluetooth activa.

import 'package:flutter/material.dart'; // Framework base de Flutter

// Widget para controlar el servo motor de la mandíbula
// Es un StatelessWidget porque el estado se maneja externamente
class ServoControl extends StatelessWidget {
  // Ángulo actual del servo (0-35 grados)
  final int servoAngle;
  // Si el control está habilitado (depende de la conexión Bluetooth)
  final bool enabled;
  // Callback que se ejecuta cuando cambia el valor del slider
  final ValueChanged<double> onChanged;

  // Constructor con parámetros requeridos
  const ServoControl({
    super.key,
    required this.servoAngle,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Márgenes laterales para separación
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white10, // Fondo semi-transparente
        borderRadius: BorderRadius.circular(28), // Bordes muy redondeados
        border: Border.all(color: Colors.white12), // Borde sutil
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinear a la izquierda
        children: [
          Row(
            children: [
              // Icono de configuración para representar control
              const Icon(Icons.settings, color: Colors.orange),
              const SizedBox(width: 10),
              // Título del control
              const Text(
                'Control de Mandíbula',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(), // Espacio flexible
              // Mostrar ángulo actual en grados
              Text(
                '$servoAngle°',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.orange, // Color naranja para resaltar
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Slider para controlar el ángulo del servo
          Slider(
            value: servoAngle.toDouble(), // Valor actual convertido a double
            min: 0, // Valor mínimo (mandíbula cerrada)
            max: 35, // Es el rango maximo que puede abrir la mandíbula física
            divisions:
                180, // 180 divisiones para control preciso (1 grado por división)
            activeColor: Colors.orange, // Color activo del slider
            inactiveColor: Colors.white24, // Color inactivo del slider
            onChanged: enabled
                ? onChanged
                : null, // Solo permitir cambios si está habilitado
          ),
          const SizedBox(height: 4),
          // Texto explicativo que cambia según el estado de conexión
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

// Fin de la clase ServoControl
// Este widget proporciona control preciso sobre el servo motor que controla
// la apertura de la mandíbula del cráneo físico, con feedback visual del ángulo actual.
