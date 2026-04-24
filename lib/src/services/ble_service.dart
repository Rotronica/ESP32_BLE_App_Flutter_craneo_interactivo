import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _huesoCharacteristic;
  BluetoothCharacteristic? _servoCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;

  final _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  final _isScanningController = StreamController<bool>.broadcast();
  final _connectionStatus = ValueNotifier<String>('Desconectado');
  final _isConnected = ValueNotifier<bool>(false);

  Stream<List<ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;
  Stream<bool> get isScanningStream => _isScanningController.stream;
  ValueNotifier<String> get connectionStatus => _connectionStatus;
  ValueNotifier<bool> get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<void> requestPermissions() async {
    try {
      // Solicitar permisos de Bluetooth
      final permissions = await Future.wait([
        Permission.bluetoothScan.request(),
        Permission.bluetoothConnect.request(),
        Permission.bluetoothAdvertise.request(),
        Permission.locationWhenInUse.request(),
      ]);

      // Verificar si todos los permisos fueron otorgados
      final allGranted = permissions.every((status) => status.isGranted);
      if (!allGranted) {
        debugPrint('No todos los permisos de Bluetooth fueron otorgados');
        throw Exception('Permisos de Bluetooth no otorgados');
      }

      // En Android, también solicita acceso a ubicación
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
      rethrow;
    }
  }

  Future<void> startScan() async {
    try {
      debugPrint('=== INICIANDO ESCANEO BLE ===');

      // Verificar si Bluetooth está habilitado
      final adapterState = await FlutterBluePlus.adapterState.first;
      debugPrint('Adapter state: $adapterState');

      if (adapterState != BluetoothAdapterState.on) {
        debugPrint('❌ Bluetooth no está habilitado');
        _connectionStatus.value = 'Habilita el Bluetooth en tu dispositivo';
        _isScanningController.add(false);
        return;
      }

      // Cancelar escaneo anterior si está en marcha
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}

      _scanResultsController.add([]);
      _isScanningController.add(true);
      _connectionStatus.value = 'Buscando dispositivos...';
      debugPrint('✓ Bluetooth habilitado, iniciando escaneo');

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 20),
        androidScanMode: AndroidScanMode.lowLatency,
        androidUsesFineLocation: true,
      );

      debugPrint('✓ Escaneo iniciado');

      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        _onScanResults,
        onError: (error) {
          debugPrint('❌ Error en escaneo: $error');
          _isScanningController.add(false);
          _connectionStatus.value = 'Error al buscar dispositivos';
        },
      );

      // Esperar a que termine el escaneo
      Future.delayed(const Duration(seconds: 20)).then((_) {
        _isScanningController.add(false);
        _connectionStatus.value = 'Búsqueda completada';
      });
    } catch (e) {
      debugPrint('❌ Error iniciando escaneo BLE: $e');
      _isScanningController.add(false);
      _connectionStatus.value = 'Error al buscar dispositivos: $e';
    }
  }

  void _onScanResults(List<ScanResult> results) {
    debugPrint('=== BLE SCAN RESULTS ===');
    debugPrint('Total results: ${results.length}');

    final filtered = results.where((result) {
      final name = result.device.platformName;
      final id = result.device.remoteId;

      debugPrint('Device: name="$name", id="$id"');

      // Si no tiene nombre, usa el ID
      if (name.isEmpty) {
        return id.str.contains('94b555f847fa') ||
            id.str.contains('94:b5:55:f8:47:fa');
      }

      final upperName = name.toUpperCase();
      return upperName.contains('CRANEO') ||
          upperName.contains('ESP32') ||
          upperName.contains('CRANEO_INTERACTIVO') ||
          id.str.contains('94b555f847fa') ||
          id.str.contains('94:b5:55:f8:47:fa');
    }).toList();

    debugPrint('Filtered results: ${filtered.length}');
    _scanResultsController.add(filtered);
  }

  Future<void> stopScan() async {
    if (await FlutterBluePlus.isScanning.first) {
      await FlutterBluePlus.stopScan();
    }
    _isScanningController.add(false);
  }

  Future<bool> connect(ScanResult result) async {
    try {
      await stopScan();
      _connectedDevice = result.device;
      _connectionStatus.value = 'Conectando a ${result.device.platformName}...';

      await _connectedDevice!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      try {
        await _discoverCharacteristics();
      } catch (e) {
        debugPrint('Error discovering characteristics: $e');
        await _connectedDevice!.disconnect();
        _connectionStatus.value = 'Error al descubrir servicios: $e';
        _resetConnection();
        return false;
      }

      _isConnected.value = true;
      _connectionStatus.value = 'Conectado a ${result.device.platformName}';

      _deviceStateSubscription?.cancel();
      _deviceStateSubscription = _connectedDevice!.connectionState.listen((
        state,
      ) {
        if (state == BluetoothConnectionState.disconnected) {
          _resetConnection();
        }
      });

      return true;
    } catch (e) {
      _connectionStatus.value = 'Error de conexión';
      debugPrint('BLE connect error: $e');
      _resetConnection();
      return false;
    }
  }

  Future<void> _discoverCharacteristics() async {
    if (_connectedDevice == null) return;

    final services = await _connectedDevice!.discoverServices();

    for (final service in services) {
      if (_isUuidMatch(service.uuid, '00ff')) {
        for (final characteristic in service.characteristics) {
          if (_isUuidMatch(characteristic.uuid, 'ff01')) {
            _huesoCharacteristic = characteristic;
          }
          if (_isUuidMatch(characteristic.uuid, 'ff02')) {
            _servoCharacteristic = characteristic;
          }
        }
      }
    }

    // Verificar que las características se encontraron
    if (_huesoCharacteristic == null || _servoCharacteristic == null) {
      throw Exception(
        'No se pudieron encontrar las características requeridas en el dispositivo.',
      );
    }
  }

  bool _isUuidMatch(Guid uuid, String pattern) {
    return uuid
        .toString()
        .replaceAll('-', '')
        .toLowerCase()
        .contains(pattern.toLowerCase());
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _resetConnection();
  }

  void _resetConnection() {
    _connectedDevice = null;
    _huesoCharacteristic = null;
    _servoCharacteristic = null;
    _isConnected.value = false;
    _connectionStatus.value = 'Desconectado';
  }

  Future<void> sendHuesoCommand(int huesoId) async {
    if (_huesoCharacteristic == null) {
      throw StateError('La característica HUESO no está disponible.');
    }

    final value = huesoId.clamp(1, 22);
    await _huesoCharacteristic!.write([value], withoutResponse: false);
  }

  Future<void> sendServoCommand(int angle) async {
    if (_servoCharacteristic == null) {
      throw StateError('La característica SERVO no está disponible.');
    }

    final value = angle.clamp(0, 180);
    await _servoCharacteristic!.write([value], withoutResponse: false);
  }

  void dispose() {
    _scanSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    _scanResultsController.close();
    _isScanningController.close();
    _connectionStatus.dispose();
    _isConnected.dispose();
  }
}
