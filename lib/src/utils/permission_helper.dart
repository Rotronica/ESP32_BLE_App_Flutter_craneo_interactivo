import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Muestra diálogo explicativo ANTES de pedir permisos
  static Future<bool> showExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bluetooth, color: Colors.blue),
            SizedBox(width: 10),
            Text('Permisos Bluetooth'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para controlar el cráneo interactivo necesitamos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.bluetooth, color: Colors.blue),
              title: Text('Bluetooth'),
              subtitle: Text('Conectar con el ESP32'),
              dense: true,
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: Colors.orange),
              title: Text('Ubicación'),
              subtitle: Text(
                'Requerido por Android (NO usamos tu ubicación real)',
              ),
              dense: true,
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, size: 16, color: Colors.blue.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu privacidad está segura, solo usamos Bluetooth',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Continuar'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  /// Muestra diálogo cuando el permiso fue denegado permanentemente
  static Future<void> showPermanentlyDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Permiso necesario'),
        content: Text(
          'Android requiere el permiso de ubicación para usar Bluetooth.\n\n'
          'Esta app NO usa tu ubicación real, es solo un requisito técnico.\n\n'
          '¿Quieres ir a configuración para activarlo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }
}
