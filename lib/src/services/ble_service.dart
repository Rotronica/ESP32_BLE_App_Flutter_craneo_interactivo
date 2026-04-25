// Archivo: ble_service.dart
// Descripción: Servicio para manejar todas las operaciones Bluetooth LE (Low Energy).
// Gestiona conexión, escaneo, permisos y comunicación con dispositivos ESP32.
// Proporciona streams para actualizar la UI en tiempo real.

import 'dart:async'; // Para manejo de streams y operaciones asíncronas

import 'package:flutter/foundation.dart'; // Para ValueNotifier y debugPrint
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Librería principal de Bluetooth
import 'package:permission_handler/permission_handler.dart'; // Para solicitar permisos

// Clase principal del servicio Bluetooth
// Maneja todo el ciclo de vida de la conexión Bluetooth con el dispositivo ESP32
class BleService {
  // Variables privadas para el estado de la conexión
  BluetoothDevice? _connectedDevice; // Dispositivo actualmente conectado
  BluetoothCharacteristic?
  _huesoCharacteristic; // Característica para comandos de huesos
  BluetoothCharacteristic?
  _servoCharacteristic; // Característica para comandos de servo

  // Suscripciones a streams para manejar eventos de Bluetooth
  StreamSubscription<List<ScanResult>>?
  _scanSubscription; // Suscripción a resultados de escaneo
  StreamSubscription<BluetoothConnectionState>?
  _deviceStateSubscription; // Suscripción a cambios de conexión

  // Controladores de streams para comunicar cambios a la UI
  final _scanResultsController =
      StreamController<List<ScanResult>>.broadcast(); // Resultados de escaneo
  final _isScanningController =
      StreamController<bool>.broadcast(); // Estado de escaneo
  final _connectionStatus = ValueNotifier<String>(
    'Desconectado',
  ); // Estado de conexión como texto
  final _isConnected = ValueNotifier<bool>(
    false,
  ); // Estado de conexión como booleano

  // Getters públicos para acceder a los streams y notifiers
  Stream<List<ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;
  Stream<bool> get isScanningStream => _isScanningController.stream;
  ValueNotifier<String> get connectionStatus => _connectionStatus;
  ValueNotifier<bool> get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Método para solicitar permisos necesarios para Bluetooth
  Future<void> requestPermissions() async {
    try {
      // Solicitar permisos esenciales para Bluetooth LE
      final permissions = await Future.wait([
        Permission.bluetoothScan.request(), // Para escanear dispositivos
        Permission.bluetoothConnect.request(), // Para conectar a dispositivos
        Permission.bluetoothAdvertise.request(), // Para anunciar (menos común)
        Permission.locationWhenInUse.request(), // Requerido en Android para BLE
      ]);

      // Verificar que todos los permisos fueron otorgados
      final allGranted = permissions.every((status) => status.isGranted);
      if (!allGranted) {
        debugPrint('No todos los permisos de Bluetooth fueron otorgados');
        throw Exception('Permisos de Bluetooth no otorgados');
      }

      // En Android, el permiso de ubicación es obligatorio para BLE
      if (defaultTargetPlatform == TargetPlatform.android) {
        final locationStatus = await Permission.location.request();
        if (!locationStatus.isGranted) {
          debugPrint('Permiso de ubicación no otorgado');
          throw Exception('Permiso de ubicación no otorgado');
        }
        debugPrint('Location permission: $locationStatus');
      }

      debugPrint('Bluetooth permissions: $permissions');
    } catch (e) {
      debugPrint('Error solicitando permisos: $e');
      rethrow; // Re-lanzar la excepción para que sea manejada por el llamador
    }
  }

  // Método para iniciar el escaneo de dispositivos Bluetooth LE
  Future<void> startScan() async {
    try {
      debugPrint('=== INICIANDO ESCANEO BLE ===');

      // Verificar el estado del adaptador Bluetooth antes de escanear
      final adapterState = await FlutterBluePlus.adapterState.first;
      debugPrint('Adapter state: $adapterState');

      // Si Bluetooth no está habilitado, mostrar mensaje y detener
      if (adapterState != BluetoothAdapterState.on) {
        debugPrint('❌ Bluetooth no está habilitado');
        _connectionStatus.value = 'Habilita el Bluetooth en tu dispositivo';
        _isScanningController.add(false); // Notificar que no se está escaneando
        return;
      }

      // Detener cualquier escaneo anterior para evitar conflictos
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {} // Ignorar errores al detener escaneo anterior

      // Limpiar resultados anteriores y notificar inicio de escaneo
      _scanResultsController.add([]);
      _isScanningController.add(true);
      _connectionStatus.value = 'Buscando dispositivos...';
      debugPrint('✓ Bluetooth habilitado, iniciando escaneo');

      // Iniciar escaneo con configuración optimizada
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10), // Escanear por 10 segundos
        androidScanMode:
            AndroidScanMode.lowLatency, // Modo de baja latencia para Android
        androidUsesFineLocation: true, // Usar ubicación precisa en Android
      );

      debugPrint('✓ Escaneo iniciado');

      // Configurar listener para resultados de escaneo
      _scanSubscription?.cancel(); // Cancelar suscripción anterior si existe
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        _onScanResults, // Método que procesa los resultados
        onError: (error) {
          debugPrint('❌ Error en escaneo: $error');
          _isScanningController.add(false);
          _connectionStatus.value = 'Error al buscar dispositivos';
        },
      );

      // Programar finalización del escaneo después del timeout
      Future.delayed(const Duration(seconds: 10)).then((_) {
        _isScanningController.add(false);
        _connectionStatus.value = 'Búsqueda completada';
      });
    } catch (e) {
      debugPrint('❌ Error iniciando escaneo BLE: $e');
      _isScanningController.add(false);
      _connectionStatus.value = 'Error al buscar dispositivos: $e';
    }
  }

  // Método privado que procesa los resultados del escaneo BLE
  void _onScanResults(List<ScanResult> results) {
    debugPrint('=== BLE SCAN RESULTS ===');
    debugPrint('Total results: ${results.length}');

    // Filtrar dispositivos para encontrar el ESP32 específico
    final filtered = results.where((result) {
      final name = result.device.platformName; // Nombre del dispositivo
      final id = result.device.remoteId; // ID único del dispositivo

      debugPrint('Device: name="$name", id="$id"');

      // Si no tiene nombre, buscar por ID específico del ESP32
      if (name.isEmpty) {
        return id.str.contains('94b555f847fa') || // ID del ESP32 sin dos puntos
            id.str.contains('94:b5:55:f8:47:fa'); // ID del ESP32 con dos puntos
      }

      // Convertir nombre a mayúsculas para comparación insensible a mayúsculas
      final upperName = name.toUpperCase();
      // Filtrar dispositivos que contengan palabras clave o el ID específico
      return upperName.contains('CRANEO') ||
          upperName.contains('ESP32') ||
          upperName.contains('CRANEO_INTERACTIVO') ||
          id.str.contains('94b555f847fa') ||
          id.str.contains('94:b5:55:f8:47:fa');
    }).toList();

    debugPrint('Filtered results: ${filtered.length}');
    // Enviar resultados filtrados al stream para actualizar la UI
    _scanResultsController.add(filtered);
  }

  // Método para detener el escaneo manualmente
  Future<void> stopScan() async {
    if (await FlutterBluePlus.isScanning.first) {
      await FlutterBluePlus.stopScan();
    }
    _isScanningController.add(false);
  }

  // Método para conectar a un dispositivo BLE específico
  Future<bool> connect(ScanResult result) async {
    try {
      // Detener escaneo antes de conectar
      await stopScan();
      _connectedDevice = result.device;
      _connectionStatus.value = 'Conectando a ${result.device.platformName}...';

      // Intentar conexión con timeout
      await _connectedDevice!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false, // No reconectar automáticamente
      );

      // Descubrir características del dispositivo
      try {
        await _discoverCharacteristics();
      } catch (e) {
        debugPrint('Error discovering characteristics: $e');
        await _connectedDevice!.disconnect();
        _connectionStatus.value = 'Error al descubrir servicios: $e';
        _resetConnection();
        return false;
      }

      // Conexión exitosa
      _isConnected.value = true;
      _connectionStatus.value = 'Conectado a ${result.device.platformName}';

      // Configurar listener para cambios en el estado de conexión
      _deviceStateSubscription?.cancel();
      _deviceStateSubscription = _connectedDevice!.connectionState.listen((
        state,
      ) {
        // Si se desconecta, resetear el estado de conexión
        if (state == BluetoothConnectionState.disconnected) {
          _resetConnection();
        }
      });

      return true; // Conexión exitosa
    } catch (e) {
      _connectionStatus.value = 'Error de conexión';
      debugPrint('BLE connect error: $e');
      _resetConnection();
      return false; // Conexión fallida
    }
  }

  // Método privado para descubrir las características BLE del dispositivo
  Future<void> _discoverCharacteristics() async {
    if (_connectedDevice == null) return;

    // Descubrir todos los servicios disponibles en el dispositivo
    final services = await _connectedDevice!.discoverServices();

    // Buscar el servicio específico (UUID que contiene '00ff')
    for (final service in services) {
      if (_isUuidMatch(service.uuid, '00ff')) {
        // Dentro del servicio, buscar las características específicas
        for (final characteristic in service.characteristics) {
          if (_isUuidMatch(characteristic.uuid, 'ff01')) {
            _huesoCharacteristic =
                characteristic; // Característica para comandos de huesos
          }
          if (_isUuidMatch(characteristic.uuid, 'ff02')) {
            _servoCharacteristic =
                characteristic; // Característica para comandos de servo
          }
        }
      }
    }

    // Verificar que ambas características fueron encontradas
    if (_huesoCharacteristic == null || _servoCharacteristic == null) {
      throw Exception(
        'No se pudieron encontrar las características requeridas en el dispositivo.',
      );
    }
  }

  // Método auxiliar para verificar si un UUID contiene un patrón específico
  bool _isUuidMatch(Guid uuid, String pattern) {
    return uuid
        .toString()
        .replaceAll('-', '') // Remover guiones del UUID
        .toLowerCase() // Convertir a minúsculas
        .contains(pattern.toLowerCase()); // Verificar si contiene el patrón
  }

  // Método para desconectar del dispositivo BLE
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _resetConnection(); // Resetear estado de conexión
  }

  // Método privado para resetear todas las variables de conexión
  void _resetConnection() {
    _connectedDevice = null;
    _huesoCharacteristic = null;
    _servoCharacteristic = null;
    _isConnected.value = false;
    _connectionStatus.value = 'Desconectado';
  }

  // Método para enviar comando de selección de hueso al ESP32
  Future<void> sendHuesoCommand(int huesoId) async {
    if (_huesoCharacteristic == null) {
      throw StateError('La característica HUESO no está disponible.');
    }

    // Asegurar que el ID del hueso esté en el rango válido (1-22)
    final value = huesoId.clamp(1, 22);
    await _huesoCharacteristic!.write([value], withoutResponse: false);
  }

  // Método para enviar comando de ángulo del servo al ESP32
  Future<void> sendServoCommand(int angle) async {
    if (_servoCharacteristic == null) {
      throw StateError('La característica SERVO no está disponible.');
    }

    // Asegurar que el ángulo esté en el rango válido (0-180 grados)
    final value = angle.clamp(0, 180);
    await _servoCharacteristic!.write([value], withoutResponse: false);
  }

  // Método para liberar recursos cuando el servicio ya no se necesita
  void dispose() {
    _scanSubscription?.cancel(); // Cancelar suscripción de escaneo
    _deviceStateSubscription
        ?.cancel(); // Cancelar suscripción de estado del dispositivo
    _scanResultsController.close(); // Cerrar stream de resultados de escaneo
    _isScanningController.close(); // Cerrar stream de estado de escaneo
    _connectionStatus.dispose(); // Liberar ValueNotifier de estado de conexión
    _isConnected.dispose(); // Liberar ValueNotifier de conexión
  }
}

// Fin de la clase BleService
// Este servicio maneja toda la comunicación Bluetooth LE con el dispositivo ESP32,
// incluyendo escaneo, conexión, descubrimiento de características y envío de comandos.
