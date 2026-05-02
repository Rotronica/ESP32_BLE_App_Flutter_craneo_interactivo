// Archivo: connection_sheet.dart
// Versión CORREGIDA - Maneja correctamente la búsqueda múltiple sin reiniciar el ESP32

// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConnectionSheet extends StatefulWidget {
  final bool isScanning;
  final List<ScanResult> scanResults;
  final Future<void> Function() onStartScan;
  final Future<void> Function(ScanResult) onConnect;
  final String status;

  const ConnectionSheet({
    super.key,
    required this.isScanning,
    required this.scanResults,
    required this.onStartScan,
    required this.onConnect,
    required this.status,
  });

  @override
  State<ConnectionSheet> createState() => _ConnectionSheetState();
}

class _ConnectionSheetState extends State<ConnectionSheet> {
  Timer? _checkTimer;
  bool _foundEsp32 = false;
  bool _showLoadingIndicator = false;

  // Control para evitar múltiples escaneos simultáneos
  bool _isStartingScan = false;

  @override
  void initState() {
    super.initState();

    _checkTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        final bool hasEsp32 = _isEsp32InResults(widget.scanResults);

        if (hasEsp32 && widget.isScanning && !_foundEsp32) {
          _foundEsp32 = true;
          _showLoadingIndicator = false;
          debugPrint('🎯 ESP32 encontrado - Ocultando indicador');
          if (mounted) setState(() {});
        }

        if (widget.isScanning && !_foundEsp32) {
          _showLoadingIndicator = true;
        } else if (!widget.isScanning) {
          _showLoadingIndicator = false;
          _foundEsp32 = false;
          _isStartingScan = false; // Resetear bandera al terminar escaneo
        }

        if (mounted) setState(() {});
      }
    });
  }

  bool _isEsp32InResults(List<ScanResult> results) {
    for (final result in results) {
      final String name = result.device.platformName.toUpperCase();
      final String id = result.device.remoteId.toString();

      if (name.contains('CRANEO') ||
          name.contains('ESP32') ||
          name.contains('CRANEO_INTERACTIVO') ||
          id.contains('94b555f847fa') ||
          id.contains('94:b5:55:f8:47:fa')) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Título
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Conectar a tu Cráneo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // Indicador de carga
          if (_showLoadingIndicator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Buscando ESP32...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else if (!widget.isScanning && widget.scanResults.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.status.contains('Habilita'))
                    const Icon(
                      Icons.bluetooth_disabled,
                      color: Colors.red,
                      size: 24,
                    )
                  else
                    const Icon(Icons.bluetooth, color: Colors.grey, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.status,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          else if (!_showLoadingIndicator &&
              widget.scanResults.isNotEmpty &&
              widget.isScanning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ESP32 encontrado!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Botón buscar - MEJORADO para evitar múltiples escaneos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: (widget.isScanning || _isStartingScan)
                  ? null
                  : () async {
                      if (_isStartingScan) return;
                      _isStartingScan = true;

                      debugPrint('🔍 Iniciando NUEVO escaneo');

                      // Reiniciar banderas
                      _foundEsp32 = false;
                      _showLoadingIndicator = true;
                      if (mounted) setState(() {});

                      // Verificar Bluetooth
                      final adapterState =
                          await FlutterBluePlus.adapterState.first;
                      if (adapterState != BluetoothAdapterState.on) {
                        _showLoadingIndicator = false;
                        _isStartingScan = false;
                        if (mounted) setState(() {});
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('Bluetooth Desactivado'),
                            content: const Text(
                              'Por favor, active el Bluetooth en la configuración de su dispositivo.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Entendido'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Iniciar escaneo
                        await widget.onStartScan();
                        _isStartingScan = false;
                        if (mounted) setState(() {});
                      }
                    },
              icon: (widget.isScanning || _isStartingScan)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh), // Cambié a icono de refresh
              label: Text(
                (widget.isScanning || _isStartingScan)
                    ? 'Buscando...'
                    : 'Buscar dispositivo',
              ), // Texto más claro
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: (widget.isScanning || _isStartingScan)
                    ? Colors.deepPurple[400]
                    : Colors.deepPurple,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Botón de limpieza de caché (nuevo)
          if (!widget.isScanning && widget.scanResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton.icon(
                onPressed: () async {
                  debugPrint('🧹 Limpiando lista de dispositivos');
                  // Forzar limpieza de resultados llamando a un nuevo escaneo
                  _foundEsp32 = false;
                  _showLoadingIndicator = true;
                  if (mounted) setState(() {});

                  // Detener cualquier escaneo activo
                  await FlutterBluePlus.stopScan();
                  await Future.delayed(const Duration(milliseconds: 200));

                  // Iniciar nuevo escaneo
                  await widget.onStartScan();
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.cleaning_services, size: 18),
                label: const Text('Limpiar y buscar de nuevo'),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ),

          const SizedBox(height: 16),

          // Lista de dispositivos
          Expanded(
            child: widget.scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.isScanning && _showLoadingIndicator
                              ? 'Buscando ESP32...\nAsegúrate que esté encendido'
                              : 'No se encontraron dispositivos\nPresiona "Buscar nuevamente"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.scanResults.length,
                    itemBuilder: (context, index) {
                      final result = widget.scanResults[index];
                      final bool isEsp32 = _isEsp32Device(result);
                      final String deviceName =
                          result.device.platformName.isEmpty
                          ? (isEsp32
                                ? 'ESP32 Cráneo'
                                : 'Dispositivo desconocido')
                          : result.device.platformName;
                      final String deviceMac = result.device.remoteId.str;
                      final int rssi = result.rssi;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        elevation: isEsp32 ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isEsp32
                              ? const BorderSide(color: Colors.green, width: 2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isEsp32
                                ? Colors.green[100]
                                : Colors.deepPurple[100],
                            child: Icon(
                              Icons.bluetooth,
                              color: isEsp32 ? Colors.green : Colors.deepPurple,
                            ),
                          ),
                          title: Text(
                            deviceName,
                            style: TextStyle(
                              fontWeight: isEsp32
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isEsp32 ? Colors.green[800] : null,
                            ),
                          ),
                          subtitle: Text(
                            deviceMac,
                            style: TextStyle(
                              fontSize: 12,
                              color: isEsp32
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                            ),
                          ),
                          trailing: Text(
                            '$rssi dBm',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getRssiColor(rssi),
                            ),
                          ),
                          onTap: () async {
                            debugPrint('🔌 Conectando a: $deviceName');
                            await widget.onConnect(result);
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Texto informativo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Si no encuentras el dispositivo, asegúrate que el ESP32 esté encendido\n'
              'y presiona "Buscar nuevamente"',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  bool _isEsp32Device(ScanResult result) {
    final String name = result.device.platformName.toUpperCase();
    final String id = result.device.remoteId.toString();

    return name.contains('CRANEO') ||
        name.contains('ESP32') ||
        name.contains('CRANEO_INTERACTIVO') ||
        id.contains('94b555f847fa') ||
        id.contains('94:b5:55:f8:47:fa');
  }

  Color _getRssiColor(int rssi) {
    if (rssi > -50) return Colors.green;
    if (rssi > -70) return Colors.lightGreen;
    if (rssi > -80) return Colors.orange;
    if (rssi > -90) return Colors.deepOrange;
    return Colors.red;
  }
}
