// Archivo: connection_sheet.dart
// Descripción: Widget que muestra una hoja modal para conectar dispositivos Bluetooth.
// Permite escanear dispositivos BLE, mostrar resultados y conectar al dispositivo seleccionado.
// Se usa como bottom sheet desde la pantalla principal.

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart'; // Framework base de Flutter
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Para tipos BLE

// Widget que representa la hoja de conexión Bluetooth
// Es un StatelessWidget porque no maneja estado interno
class ConnectionSheet extends StatelessWidget {
  // Propiedades del widget - todas requeridas
  final bool isScanning; // Indica si se está escaneando actualmente
  final List<ScanResult> scanResults; // Lista de dispositivos encontrados
  final Future<void> Function() onStartScan; // Callback para iniciar escaneo
  final Future<void> Function(ScanResult)
  onConnect; // Callback para conectar a dispositivo
  final String status; // Estado actual de la conexión como texto

  // Constructor con parámetros requeridos
  const ConnectionSheet({
    super.key,
    required this.isScanning,
    required this.scanResults,
    required this.onStartScan,
    required this.onConnect,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Altura de la hoja modal (70% de la pantalla)
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ), // Bordes redondeados arriba
      ),
      child: Column(
        children: [
          // Indicador visual de que es una hoja deslizable (handle)
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
          // Título de la hoja
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Conectar a tu Cráneo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          // Mostrar indicador de carga si se está escaneando
          if (isScanning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(), // Spinner de carga
                  const SizedBox(width: 12),
                  const Text('Buscando dispositivos...'), // Texto de estado
                ],
              ),
            )
          else
            // Mostrar estado actual cuando no se está escaneando
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono que cambia según el estado de Bluetooth
                  if (isScanning)
                    const Icon(
                      Icons.bluetooth_searching,
                      color: Colors.deepPurple,
                      size: 24,
                    )
                  else if (status.contains(
                    'Habilita',
                  )) // Bluetooth deshabilitado
                    const Icon(
                      Icons.bluetooth_disabled,
                      color: Colors.red,
                      size: 24,
                    )
                  else // Estado normal
                    const Icon(Icons.bluetooth, color: Colors.grey, size: 24),
                  const SizedBox(width: 8),
                  // Texto del estado actual
                  Expanded(
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Botón para iniciar el escaneo de dispositivos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: isScanning
                  ? null // Deshabilitar botón durante escaneo
                  : () async {
                      // Verificar estado del adaptador Bluetooth antes de escanear
                      final adapterState =
                          await FlutterBluePlus.adapterState.first;
                      if (adapterState != BluetoothAdapterState.on) {
                        // Mostrar diálogo si Bluetooth está desactivado
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Bluetooth Desactivado'),
                              content: const Text(
                                'Por favor, active el Bluetooth en la configuración de su dispositivo para buscar dispositivos.',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Entendido'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        // Iniciar escaneo si Bluetooth está habilitado
                        onStartScan();
                      }
                    },
              // Icono del botón que cambia según estado
              icon: isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white, // Spinner blanco sobre fondo púrpura
                      ),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(isScanning ? 'Buscando...' : 'Buscar dispositivos'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  48,
                ), // Botón de ancho completo
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista de dispositivos encontrados o mensaje de vacío
          Expanded(
            child: scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icono cuando no hay dispositivos
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        // Texto que cambia según si se está escaneando o no
                        Text(
                          isScanning
                              ? 'Buscando dispositivos...'
                              : 'No se encontraron dispositivos',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        // Mostrar botón de reintento solo cuando no se está escaneando
                        if (!isScanning) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => onStartScan(),
                            child: const Text('Intentar de nuevo'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: scanResults.length,
                    itemBuilder: (context, index) {
                      final result = scanResults[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          // Icono de Bluetooth para cada dispositivo
                          leading: const Icon(
                            Icons.bluetooth,
                            color: Colors.deepPurple,
                          ),
                          // Nombre del dispositivo (o nombre por defecto si está vacío)
                          title: Text(
                            result.device.platformName.isEmpty
                                ? 'ESP32 Cráneo'
                                : result.device.platformName,
                          ),
                          // ID único del dispositivo como subtítulo
                          subtitle: Text(result.device.remoteId.str),
                          // Intensidad de señal RSSI
                          trailing: Text('${result.rssi} dBm'),
                          // Al tocar, intentar conectar al dispositivo
                          onTap: () => onConnect(result),
                        ),
                      );
                    },
                  ),
          ),
          // Texto informativo al final de la hoja
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Asegúrate de que el ESP32 esté encendido y con el servicio BLE activo.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Fin de la clase ConnectionSheet
// Este widget proporciona una interfaz completa para la conexión Bluetooth,
// incluyendo escaneo, visualización de dispositivos y manejo de estados.
