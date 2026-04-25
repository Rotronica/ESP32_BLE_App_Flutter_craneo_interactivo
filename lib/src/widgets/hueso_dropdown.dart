// Archivo: hueso_dropdown.dart
// Descripción: Widget dropdown para seleccionar huesos del cráneo.
// Muestra una lista desplegable con todos los huesos, cada uno con su color único
// y número de identificación para facilitar la selección.

import 'package:flutter/material.dart'; // Framework base de Flutter
import '../models/hueso.dart'; // Modelo de datos del hueso

// Widget dropdown para selección de huesos del cráneo
// Es un StatelessWidget porque la selección se maneja externamente
class HuesoDropdown extends StatelessWidget {
  // Propiedad opcional: hueso actualmente seleccionado
  final HuesoCraneo? selectedHueso;
  // Lista completa de huesos disponibles
  final List<HuesoCraneo> huesos;
  // Callback que se ejecuta cuando cambia la selección
  final ValueChanged<HuesoCraneo?> onChanged;

  // Constructor con parámetros requeridos
  const HuesoDropdown({
    super.key,
    required this.selectedHueso,
    required this.huesos,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ocupar todo el ancho disponible
      decoration: BoxDecoration(
        color: Colors.grey[850], // Fondo gris oscuro
        borderRadius: BorderRadius.circular(12), // Bordes redondeados
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButton<HuesoCraneo>(
        value: selectedHueso, // Valor actualmente seleccionado
        isExpanded: true, // Expandir para ocupar todo el ancho
        hint: const Text(
          'Selecciona un hueso...',
          style: TextStyle(color: Colors.grey), // Texto gris para el hint
        ),
        // Crear elementos del dropdown para cada hueso
        items: huesos.map((hueso) {
          return DropdownMenuItem<HuesoCraneo>(
            value: hueso,
            child: Row(
              children: [
                // Círculo de color único del hueso
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: hueso.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Texto con ID y nombre del hueso
                Expanded(
                  child: Text(
                    '${hueso.id}. ${hueso.nombre}', // ✅ Nombre e ID del hueso
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis, // Cortar texto largo
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged, // Callback cuando cambia la selección
        underline:
            const SizedBox.shrink(), // Remover línea inferior por defecto
        dropdownColor: Colors.grey[850], // Color de fondo del menú desplegable
        icon: const Icon(
          Icons.arrow_drop_down,
          color: Colors.deepPurple,
        ), // Icono personalizado
      ),
    );
  }
}

// Fin de la clase HuesoDropdown
// Este widget proporciona una interfaz intuitiva para seleccionar huesos del cráneo,
// mostrando cada hueso con su color identificativo y número de ID.
