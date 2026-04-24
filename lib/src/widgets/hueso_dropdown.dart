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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.select_all, color: Colors.deepPurple, size: 24),
              SizedBox(width: 12),
              Text(
                'Selecciona un hueso',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<HuesoCraneo>(
            initialValue: selectedHueso,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withAlpha((0.1 * 255).round()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.deepPurple,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            hint: const Text(
              'Elige un hueso del cráneo...',
              style: TextStyle(color: Colors.white70),
            ),
            items: huesos
                .map(
                  (hueso) => DropdownMenuItem<HuesoCraneo>(
                    value: hueso,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: hueso.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hueso.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                hueso.nombreCientifico,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }
}
