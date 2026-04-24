import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../models/hueso.dart';
import '../services/ble_service.dart';
import '../widgets/connection_sheet.dart';
import '../widgets/hueso_info_card.dart';
import '../widgets/hueso_dropdown.dart';
import '../widgets/servo_control.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  final List<HuesoCraneo> _huesos = huesosCraneo;
  HuesoCraneo? _selectedHueso;
  int _servoAngle = 90;
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  late final StreamSubscription<List<ScanResult>> _scanSubscription;
  late final StreamSubscription<bool> _scanningSubscription;

  @override
  void initState() {
    super.initState();
    _initializePermissionsAndBLE();
    _scanSubscription = _bleService.scanResultsStream.listen((results) {
      setState(() {
        _scanResults = results;
      });
    });
    _scanningSubscription = _bleService.isScanningStream.listen((scanning) {
      setState(() {
        _isScanning = scanning;
      });
    });
  }

  Future<void> _initializePermissionsAndBLE() async {
    await _bleService.requestPermissions();
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
    _scanSubscription.cancel();
    _scanningSubscription.cancel();
    _bleService.dispose();
    super.dispose();
  }

  Future<void> _selectHueso(HuesoCraneo hueso) async {
    setState(() {
      _selectedHueso = hueso;
    });

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

  Future<void> _updateServo(double value) async {
    final angle = value.round();
    setState(() {
      _servoAngle = angle;
    });

    if (_bleService.isConnected.value) {
      try {
        await _bleService.sendServoCommand(angle);
      } catch (e) {
        debugPrint('Error enviando comando SERVO: $e');
      }
    }
  }

  void _showConnectionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ConnectionSheet(
          isScanning: _isScanning,
          scanResults: _scanResults,
          onStartScan: _bleService.startScan,
          onConnect: (result) async {
            final connected = await _bleService.connect(result);
            if (!mounted) return;
            if (connected) {
              Navigator.of(this.context).pop();
            }
          },
          status: _bleService.connectionStatus.value,
        );
      },
    );
  }

  Widget _buildModelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            'Cráneo 3D (Rotando)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
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
                color: Colors.deepPurple.withAlpha((0.3 * 255).round()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Intenta mostrar el modelo 3D
                ModelViewer(
                  src: 'assets/models/craneo.glb',
                  alt: 'Modelo 3D del cráneo',
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: Colors.black,
                  ar: false,
                ),
                // Overlay con información del hueso seleccionado
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
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedHueso!.color,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedHueso!.nombre,
                                style: TextStyle(
                                  color: _selectedHueso!.color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedHueso!.nombreCientifico,
                                style: TextStyle(
                                  color: _selectedHueso!.color.withAlpha(
                                    (0.8 * 255).round(),
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cráneo Interactivo'),
        centerTitle: true,
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
                      (0.2 * 255).round(),
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
                      Icon(
                        connected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: connected ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _buildModelSection(),
                    const SizedBox(height: 20),
                    // Dropdown para seleccionar huesos
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: HuesoDropdown(
                        selectedHueso: _selectedHueso,
                        huesos: _huesos,
                        onChanged: (hueso) {
                          if (hueso != null) {
                            _selectHueso(hueso);
                          }
                        },
                      ),
                    ),
                    // Información del hueso seleccionado
                    if (_selectedHueso != null) ...[
                      const SizedBox(height: 16),
                      HuesoInfoCard(hueso: _selectedHueso!),
                    ],
                    const SizedBox(height: 20),
                    // Control del servo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ServoControl(
                        servoAngle: _servoAngle,
                        enabled: _bleService.isConnected.value,
                        onChanged: _updateServo,
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
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _bleService.isConnected,
        builder: (context, connected, child) {
          return FloatingActionButton.extended(
            onPressed: connected
                ? _bleService.disconnect
                : _showConnectionSheet,
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
