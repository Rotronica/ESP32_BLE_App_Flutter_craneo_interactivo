// Archivo: home_screen.dart
// Descripción: Pantalla principal de la aplicación que muestra el modelo 3D del cráneo,
// controles de servos, búsqueda de dispositivos Bluetooth y información de huesos.
// Esta pantalla integra todas las funcionalidades principales de la app.

import 'dart:async'; // Para manejo de streams y temporizadores

import 'package:flutter/material.dart'; // Framework base de Flutter
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Para comunicación Bluetooth LE
import 'package:model_viewer_plus/model_viewer_plus.dart'; // Para mostrar modelos 3D

import '../models/hueso.dart'; // Modelo de datos de los huesos del cráneo
import '../services/ble_service.dart'; // Servicio para manejar conexiones Bluetooth
import '../widgets/connection_sheet.dart'; // Widget para mostrar hoja de conexión
import '../widgets/hueso_info_card.dart'; // Widget para mostrar información de huesos
import '../widgets/hueso_dropdown.dart'; // Widget dropdown para seleccionar huesos
import '../widgets/servo_control.dart'; // Widget para controlar servos

// Clase principal de la pantalla home
// Esta clase maneja el estado de la aplicación y coordina todas las funcionalidades
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Estado de la pantalla home
// Maneja el estado de conexión Bluetooth, selección de huesos, control de servos y modelo 3D
class _HomeScreenState extends State<HomeScreen> {
  // Servicio para manejar todas las operaciones Bluetooth
  final BleService _bleService = BleService();

  // Lista completa de huesos del cráneo cargada desde el modelo
  final List<HuesoCraneo> _huesos = huesosCraneo;

  // Hueso actualmente seleccionado por el usuario
  HuesoCraneo? _selectedHueso;

  // Ángulo actual del servo (0-180 grados)
  int _servoAngle = 0;

  // Lista de dispositivos Bluetooth encontrados durante el escaneo
  List<ScanResult> _scanResults = [];

  // Estado de escaneo Bluetooth (true = escaneando, false = detenido)
  bool _isScanning = false;

  // Modelo 3D actualmente mostrado
  String _currentModel = 'assets/models/craneo.glb';

  // Key única para forzar la reconstrucción del ModelViewer
  Key _modelViewerKey = UniqueKey();

  // Suscripciones a streams para actualizar la UI en tiempo real
  late final StreamSubscription<List<ScanResult>> _scanSubscription;
  late final StreamSubscription<bool> _scanningSubscription;

  @override
  void initState() {
    super.initState();
    // Inicializar permisos y Bluetooth, pero no el modelo 3D para evitar bloqueo inicial
    _initializePermissionsAndBLE();

    // Suscribirse al stream de resultados de escaneo para actualizar la lista de dispositivos
    _scanSubscription = _bleService.scanResultsStream.listen((results) {
      setState(() {
        _scanResults = results;
      });
    });

    // Suscribirse al stream de estado de escaneo para mostrar indicadores de carga
    _scanningSubscription = _bleService.isScanningStream.listen((scanning) {
      setState(() {
        _isScanning = scanning;
      });
    });
  }

  // Método para inicializar permisos y Bluetooth al iniciar la app
  Future<void> _initializePermissionsAndBLE() async {
    // Solicitar permisos necesarios para Bluetooth
    await _bleService.requestPermissions();

    // Mostrar mensaje informativo al usuario sobre permisos
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permisos de Bluetooth solicitados. Toca conectar para buscar dispositivos.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Cancelar suscripciones para evitar memory leaks
    _scanSubscription.cancel();
    _scanningSubscription.cancel();

    // Liberar recursos del servicio Bluetooth
    _bleService.dispose();

    super.dispose();
  }

  // Método para seleccionar un hueso y enviar comando Bluetooth si está conectado
  Future<void> _selectHueso(HuesoCraneo hueso) async {
    // Actualizar el estado con el hueso seleccionado
    setState(() {
      _selectedHueso = hueso;
      // Cambiar el modelo 3D al del hueso seleccionado si tiene modelo
      if (hueso.modelFile.isNotEmpty) {
        _currentModel = 'assets/models/${hueso.modelFile}';
        debugPrint('Cambiando modelo a: $_currentModel');
      } else {
        _currentModel = 'assets/models/craneo.glb'; // Mantener el cráneo si no tiene modelo específico
        debugPrint('Manteniendo modelo craneo: $_currentModel');
      }
      // Forzar reconstrucción del ModelViewer con nueva key
      _modelViewerKey = UniqueKey();
    });

    // Si hay conexión Bluetooth activa, enviar comando para resaltar el hueso
    if (_bleService.isConnected.value) {
      try {
        await _bleService.sendHuesoCommand(hueso.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enviando comando para ${hueso.nombre}')),
        );
      } catch (e) {
        debugPrint('Error enviando comando HUESO: $e');
      }
    }
  }

  // Método para actualizar el ángulo del servo y enviar comando Bluetooth
  Future<void> _updateServo(double value) async {
    // Convertir el valor del slider a entero (ángulo en grados)
    final angle = value.round();
    setState(() {
      _servoAngle = angle;
    });

    // Si hay conexión Bluetooth, enviar comando para mover el servo
    if (_bleService.isConnected.value) {
      try {
        await _bleService.sendServoCommand(angle);
      } catch (e) {
        debugPrint('Error enviando comando SERVO: $e');
      }
    }
  }

  // Método para mostrar la hoja modal de conexión Bluetooth
  void _showConnectionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // Permitir que la hoja ocupe más espacio
      backgroundColor:
          Colors.transparent, // Fondo transparente para mejor apariencia
      builder: (context) {
        return ConnectionSheet(
          isScanning: _isScanning, // Estado actual de escaneo
          scanResults: _scanResults, // Lista de dispositivos encontrados
          onStartScan: _bleService.startScan, // Función para iniciar escaneo
          onConnect: (result) async {
            // Intentar conectar al dispositivo seleccionado
            final connected = await _bleService.connect(result);
            if (!mounted) return;
            if (connected) {
              // Cerrar la hoja modal si la conexión fue exitosa
              Navigator.of(this.context).pop();
            }
          },
          status:
              _bleService.connectionStatus.value, // Estado de conexión actual
        );
      },
    );
  }

  // Método para construir la sección del modelo 3D
  Widget _buildModelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección del modelo 3D
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            'Modelo 3D (Rotando)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Contenedor del modelo 3D con diseño atractivo
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.black, Colors.grey[900]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withAlpha(
                  (0.3 * 255).round(),
                ), // Sombra púrpura sutil
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Mostrar el modelo 3D
                ModelViewer(
                  key: _modelViewerKey, // Key única para forzar reconstrucción
                  backgroundColor: Colors.transparent,
                  src: _currentModel, // Modelo actual
                  alt: 'Modelo 3D del hueso seleccionado',
                  ar: true, // Habilitar realidad aumentada
                  arModes: [
                    'scene-viewer',
                    'webxr',
                    'quick-look',
                  ], // Modos AR soportados
                  autoRotate: true, // Rotación automática
                  cameraControls: true, // Controles de cámara
                  disableZoom: false, // Permitir zoom
                  loading: Loading.eager, // Carga inmediata
                ),
                // Overlay que muestra información del hueso seleccionado sobre el modelo 3D
                Positioned(
                  top: 12,
                  right: 12,
                  left: 12,
                  child: _selectedHueso != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87, // Fondo semi-transparente
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedHueso!
                                  .color, // Borde del color del hueso
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Nombre común del hueso
                              Text(
                                _selectedHueso!.nombre,
                                style: TextStyle(
                                  color: _selectedHueso!.color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Nombre científico del hueso
                              Text(
                                _selectedHueso!.nombreCientifico,
                                style: TextStyle(
                                  color: _selectedHueso!.color.withAlpha(
                                    (0.8 * 255).round(), // Opacidad reducida
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(), // No mostrar nada si no hay hueso seleccionado
                ),
              ],
            ),
          ),
        ),
        // Texto explicativo sobre el funcionamiento del modelo 3D
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'El cráneo se gira automáticamente. Selecciona un hueso en la lista para verlo destacado.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // Método build principal que construye toda la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior de la aplicación
      appBar: AppBar(
        title: const Text('Cráneo Interactivo'),
        centerTitle: true,
        // Botón de menú para abrir el drawer
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        // Indicador de estado de conexión Bluetooth en la esquina superior derecha
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _bleService.isConnected,
            builder: (context, connected, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (connected ? Colors.green : Colors.red).withAlpha(
                      (0.2 * 255).round(), // Fondo semi-transparente
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: connected ? Colors.green : Colors.red,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icono que cambia según estado de conexión
                      Icon(
                        connected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: connected ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      // Texto que indica estado de conexión
                      Text(
                        connected ? 'Conectado' : 'Desconectado',
                        style: TextStyle(
                          color: connected ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // Panel lateral (drawer) con menú de opciones
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Encabezado del drawer
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Cráneo Interactivo',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // Opción "Acerca de" en el drawer
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.of(context).pop(); // Cerrar el drawer
                // Mostrar diálogo "Acerca de" con información de la app
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Acerca de'),
                    content: const SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cráneo Interactivo'),
                          Text('Versión: 0.1.0'),
                          Text('© 2026 Rodrigo C.C.'),
                          SizedBox(height: 16),
                          Text('Desarrollado por Rodrigo C.C.'),
                          Text(
                            'Aplicación para interactuar con modelo 3D de cráneo vía Bluetooth.',
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Licencia:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('MIT License'),
                          SizedBox(height: 8),
                          Text(
                            'Copyright (c) 2026 Rodrigo C.C.\n\n'
                            'Permission is hereby granted, free of charge, to any person obtaining a copy '
                            'of this software and associated documentation files (the "Software"), to deal '
                            'in the Software without restriction, including without limitation the rights '
                            'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
                            'copies of the Software, and to permit persons to whom the Software is '
                            'furnished to do so, subject to the following conditions:\n\n'
                            'The above copyright notice and this permission notice shall be included in all '
                            'copies or substantial portions of the Software.\n\n'
                            'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
                            'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
                            'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
                            'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
                            'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '
                            'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '
                            'SOFTWARE.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      // Cuerpo principal de la pantalla
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(), // Efecto de rebote al hacer scroll
                padding: EdgeInsets.only(
                  top: 12,
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                child: Column(
                  children: [
                    // Sección del modelo 3D
                    _buildModelSection(),
                    const SizedBox(height: 20),
                    // Dropdown para seleccionar huesos del cráneo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: HuesoDropdown(
                        selectedHueso: _selectedHueso,
                        huesos: _huesos,
                        onChanged: (hueso) {
                          if (hueso != null) {
                            _selectHueso(hueso); // Llamar método de selección
                          }
                        },
                      ),
                    ),
                    // Mostrar información del hueso solo si hay uno seleccionado
                    if (_selectedHueso != null) ...[
                      const SizedBox(height: 16),
                      // Botón para resetear al cráneo completo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedHueso = null;
                              _currentModel = 'assets/models/craneo.glb';
                              _modelViewerKey = UniqueKey();
                              debugPrint('Reseteando a modelo craneo completo');
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Ver Cráneo Completo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      HuesoInfoCard(
                        hueso: _selectedHueso!,
                      ), // Tarjeta con info detallada
                    ],
                    const SizedBox(height: 20),
                    // Control deslizante para el servo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ServoControl(
                        servoAngle: _servoAngle,
                        enabled: _bleService
                            .isConnected
                            .value, // Habilitado solo si conectado
                        onChanged:
                            _updateServo, // Callback para cambios en el ángulo
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Botón flotante para conectar/desconectar Bluetooth
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _bleService.isConnected,
        builder: (context, connected, child) {
          return FloatingActionButton.extended(
            onPressed: connected
                ? _bleService
                      .disconnect // Desconectar si está conectado
                : _showConnectionSheet, // Mostrar hoja de conexión si no está conectado
            icon: Icon(
              connected ? Icons.power_settings_new : Icons.bluetooth_searching,
            ),
            label: Text(connected ? 'Desconectar' : 'Conectar'),
            backgroundColor: connected ? Colors.red : Colors.deepPurple,
          );
        },
      ),
    );
  }
}

// Fin de la clase HomeScreen
// Esta pantalla integra todas las funcionalidades: modelo 3D, selección de huesos,
// control de servos y conexión Bluetooth
