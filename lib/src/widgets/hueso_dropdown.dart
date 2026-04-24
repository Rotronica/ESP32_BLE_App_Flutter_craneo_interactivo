import 'package:flutter/material.dart';
import '../models/hueso.dart';

class HuesoDropdown extends StatelessWidget {
  final HuesoCraneo? selectedHueso;
  final List<HuesoCraneo> huesos;
  final ValueChanged<HuesoCraneo?> onChanged;

  const HuesoDropdown({
    super.key,
    required this.selectedHueso,
    required this.huesos,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButton<HuesoCraneo>(
        value: selectedHueso,
        isExpanded: true,
        hint: const Text(
          'Selecciona un hueso...',
          style: TextStyle(color: Colors.grey),
        ),
        items: huesos.map((hueso) {
          return DropdownMenuItem<HuesoCraneo>(
            value: hueso,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: hueso.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${hueso.id}. ${hueso.nombre}', // ✅ Solo el nombre
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        dropdownColor: Colors.grey[850],
        icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
      ),
    );
  }
}
