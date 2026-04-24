import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConnectionSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Conectar a tu Cráneo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              status,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: isScanning ? null : () => onStartScan(),
              icon: isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(isScanning ? 'Buscando...' : 'Buscar dispositivos'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: scanResults.isEmpty
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
                          isScanning
                              ? 'Buscando dispositivos...'
                              : 'No se encontraron dispositivos',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
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
                          leading: const Icon(
                            Icons.bluetooth,
                            color: Colors.deepPurple,
                          ),
                          title: Text(
                            result.device.platformName.isEmpty
                                ? 'ESP32 Cráneo'
                                : result.device.platformName,
                          ),
                          subtitle: Text(result.device.remoteId.str),
                          trailing: Text('${result.rssi} dBm'),
                          onTap: () => onConnect(result),
                        ),
                      );
                    },
                  ),
          ),
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
