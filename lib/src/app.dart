// Importa el paquete principal de Flutter para widgets Material Design
import 'package:flutter/material.dart';
// Importa la pantalla principal de la aplicación
import 'screens/home_screen.dart';

// Clase principal de la aplicación que extiende StatelessWidget
// Esta clase configura el MaterialApp con el tema y la pantalla inicial
class CraneoApp extends StatelessWidget {
  // Constructor constante con key opcional
  const CraneoApp({super.key});

  // Método build que construye la interfaz de la aplicación
  @override
  Widget build(BuildContext context) {
    // Retorna un MaterialApp que es el widget raíz de apps Flutter
    return MaterialApp(
      // Título de la aplicación (aparece en el selector de apps)
      title: 'Cráneo Interactivo',
      // Oculta el banner de debug en la esquina superior derecha
      debugShowCheckedModeBanner: false,
      // Configuración del tema oscuro con Material Design 3
      theme: ThemeData(
        // Esquema de colores generado a partir de un color semilla
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, // Color base para generar la paleta
          brightness: Brightness.dark, // Tema oscuro
        ),
        // Habilita Material Design 3 para componentes modernos
        useMaterial3: true,
      ),
      // Pantalla inicial de la aplicación
      home: const HomeScreen(),
    );
  }
}
