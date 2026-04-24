import 'package:flutter/material.dart';

import '../models/hueso.dart';

class HuesoGrid extends StatelessWidget {
  final List<HuesoCraneo> huesos;
  final HuesoCraneo? selectedHueso;
  final ValueChanged<HuesoCraneo> onSelected;

  const HuesoGrid({
    super.key,
    required this.huesos,
    required this.selectedHueso,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: huesos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final hueso = huesos[index];
        final isSelected = selectedHueso?.id == hueso.id;

        return GestureDetector(
          onTap: () => onSelected(hueso),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? hueso.color.withAlpha((0.95 * 255).round())
                  : Colors.white10,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white12,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: hueso.color,
                      child: Text(
                        hueso.id.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  hueso.nombre,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hueso.nombreCientifico,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.black54 : Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
