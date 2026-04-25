// Archivo: hueso_info_card.dart
// Descripción: Widget que muestra información detallada de un hueso del cráneo.
// Incluye nombre, nombre científico, descripción y dato curioso en una tarjeta atractiva.
// El diseño usa el color único del hueso para crear una experiencia visual coherente.

import 'package:flutter/material.dart'; // Framework base de Flutter

import '../models/hueso.dart'; // Modelo de datos del hueso

// Widget que muestra información detallada de un hueso del cráneo
// Es un StatelessWidget porque solo muestra datos, no maneja estado
class HuesoInfoCard extends StatelessWidget {
  // Propiedad requerida: el hueso cuya información se mostrará
  final HuesoCraneo hueso;

  // Constructor que requiere el hueso
  const HuesoInfoCard({super.key, required this.hueso});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Márgenes laterales para separación del borde de la pantalla
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20), // Padding interno
      decoration: BoxDecoration(
        // Gradiente que usa el color del hueso con diferentes opacidades
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hueso.color.withAlpha(
              (0.95 * 255).round(),
            ), // Color casi sólido arriba
            hueso.color.withAlpha(
              (0.75 * 255).round(),
            ), // Color más transparente abajo
          ],
        ),
        borderRadius: BorderRadius.circular(24), // Bordes muy redondeados
        boxShadow: [
          BoxShadow(
            color: hueso.color.withAlpha(
              (0.35 * 255).round(),
            ), // Sombra del color del hueso
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Alinear contenido a la izquierda
        children: [
          Row(
            children: [
              // Barra vertical blanca como indicador visual
              Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // Contenido principal de la tarjeta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre común del hueso en grande y negrita
                    Text(
                      hueso.nombre,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Nombre científico en itálica y más pequeño
                    Text(
                      hueso.nombreCientifico,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(
                          (0.85 * 255).round(),
                        ), // Blanco ligeramente transparente
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Descripción detallada del hueso
          Text(
            hueso.descripcion,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(
                (0.95 * 255).round(),
              ), // Blanco casi opaco
              height: 1.5, // Espaciado de línea para mejor legibilidad
            ),
          ),
          const SizedBox(height: 12),
          // Contenedor especial para el dato curioso
          Container(
            padding: const EdgeInsets.all(14), // Padding interno
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(
                (0.2 * 255).round(),
              ), // Fondo blanco semi-transparente
              borderRadius: BorderRadius.circular(16), // Bordes redondeados
            ),
            child: Row(
              children: [
                // Icono de bombilla para indicar "dato curioso"
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                // Texto del dato curioso
                Expanded(
                  child: Text(
                    hueso.datoCurioso,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
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

// Fin de la clase HuesoInfoCard
// Este widget crea una tarjeta visualmente atractiva que muestra toda la información
// educativa de un hueso del cráneo, usando el color único del hueso para el diseño.
