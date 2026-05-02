// Archivo: ble_service.dart
// Versión CORREGIDA - Sin errores de compilación

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class BleService {
  // Variables privadas
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _huesoCharacteristic;
  BluetoothCharacteristic? _servoCharacteristic;

  // Suscripciones
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;

  // Controladores de streams
  final _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  final _isScanningController = StreamController<bool>.broadcast();
  final _connectionStatus = ValueNotifier<String>('Desconectado');
  final _isConnected = ValueNotifier<bool>(false);

  // Para información del dispositivo
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Getters públicos
  Stream<List<ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;
  Stream<bool> get isScanningStream => _isScanningController.stream;
  ValueNotifier<String> get connectionStatus => _connectionStatus;
  ValueNotifier<bool> get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Getters para diagnóstico
  bool get isHuesoCharacteristicReady => _huesoCharacteristic != null;
  bool get isServoCharacteristicReady => _servoCharacteristic != null;

  // ============================================================
  // PERMISOS
  // ============================================================

  Future<bool> requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _requestAndroidPermissions();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await _requestIOSPermissions();
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await _deviceInfo.androidInfo;
      final isAndroid12OrAbove = androidInfo.version.sdkInt >= 31;

      if (isAndroid12OrAbove) {
        final scanGranted = await Permission.bluetoothScan.isGranted;
        final connectGranted = await Permission.bluetoothConnect.isGranted;
        final locationGranted = await Permission.locationWhenInUse.isGranted;
        return scanGranted && connectGranted && locationGranted;
      } else {
        final bluetoothGranted = await Permission.bluetooth.isGranted;
        final locationGranted = await Permission.locationWhenInUse.isGranted;
        return bluetoothGranted && locationGranted;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await Permission.bluetooth.isGranted;
    }
    return false;
  }

  Future<bool> _requestAndroidPermissions() async {
    final androidInfo = await _deviceInfo.androidInfo;
    final isAndroid12OrAbove = androidInfo.version.sdkInt >= 31;

    List<Permission> requiredPermissions = [];

    if (isAndroid12OrAbove) {
      requiredPermissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];
      debugPrint('📱 Android 12+ - Permisos BLE modernos');
    } else {
      requiredPermissions = [
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ];
      debugPrint('📱 Android legacy - Permisos clásicos');
    }

    final Map<Permission, PermissionStatus> statuses = await requiredPermissions
        .request();

    bool allGranted = true;
    for (var permission in requiredPermissions) {
      final status = statuses[permission];
      if (status == null || !status.isGranted) {
        debugPrint('❌ Permiso denegado: ${permission.toString()}');
        allGranted = false;
      } else {
        debugPrint('✅ Permiso concedido: ${permission.toString()}');
      }
    }

    return allGranted;
  }

  Future<bool> _requestIOSPermissions() async {
    final status = await Permission.bluetooth.request();
    final granted = status.isGranted;
    debugPrint(granted ? '✅ Permiso iOS concedido' : '❌ Permiso iOS denegado');
    return granted;
  }

  // ============================================================
  // ESCANEO
  // ============================================================

  Future<void> startScan() async {
    try {
      debugPrint('=== 🔍 INICIANDO ESCANEO BLE ===');

      if (!await hasPermissions()) {
        _connectionStatus.value = '⚠️ Se requieren permisos';
        debugPrint('❌ Sin permisos para escanear');
        return;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      debugPrint('📶 Estado adaptador: $adapterState');

      if (adapterState != BluetoothAdapterState.on) {
        _connectionStatus.value = '📴 Habilita Bluetooth';
        _isScanningController.add(false);
        return;
      }

      await FlutterBluePlus.stopScan();
      await Future.delayed(const Duration(milliseconds: 100));

      _scanResultsController.add([]);
      _isScanningController.add(true);
      _connectionStatus.value = '🔍 Buscando ESP32...';

      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        _onScanResults,
        onError: (error) {
          debugPrint('❌ Error escaneo: $error');
          _isScanningController.add(false);
        },
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        androidScanMode: AndroidScanMode.lowLatency,
      );

      debugPrint('✅ Escaneo iniciado');

      Future.delayed(const Duration(seconds: 5)).then((_) {
        _isScanningController.add(false);
      });
    } catch (e) {
      debugPrint('❌ Error iniciando escaneo: $e');
      _isScanningController.add(false);
      _connectionStatus.value = '❌ Error: $e';
    }
  }

  void _onScanResults(List<ScanResult> results) {
    final filtered = results.where((result) {
      final name = result.device.platformName;
      final id = result.device.remoteId.toString();
      final upperName = name.toUpperCase();

      return upperName.contains('CRANEO') ||
          upperName.contains('ESP32') ||
          id.contains('94b555f847fa') ||
          id.contains('94:b5:55:f8:47:fa');
    }).toList();

    debugPrint(
      '📡 Encontrados: ${results.length} | Filtrados: ${filtered.length}',
    );
    _scanResultsController.add(filtered);
  }

  Future<void> stopScan() async {
    if (await FlutterBluePlus.isScanning.first) {
      await FlutterBluePlus.stopScan();
      debugPrint('🛑 Escaneo detenido');
    }
    _isScanningController.add(false);
  }

  // ============================================================
  // CONEXIÓN Y DESCUBRIMIENTO DE CARACTERÍSTICAS
  // ============================================================

  Future<bool> connect(ScanResult result) async {
    try {
      debugPrint('========================================');
      debugPrint('🔌 Intentando conectar a: ${result.device.platformName}');
      debugPrint('📡 MAC: ${result.device.remoteId}');
      debugPrint('========================================');

      await stopScan();
      _connectedDevice = result.device;
      _connectionStatus.value = '🔌 Conectando...';

      // Conectar al dispositivo
      await _connectedDevice!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      debugPrint('✅ Dispositivo conectado, descubriendo servicios...');
      _connectionStatus.value = '🔍 Descubriendo servicios...';

      // Esperar un momento para que el dispositivo esté listo
      await Future.delayed(const Duration(milliseconds: 500));

      // Descubrir características
      final discovered = await _discoverCharacteristics();

      if (!discovered) {
        debugPrint('❌ No se pudieron descubrir las características');
        await _connectedDevice!.disconnect();
        _resetConnection();
        _connectionStatus.value = '❌ Error: Características no encontradas';
        return false;
      }

      _isConnected.value = true;
      _connectionStatus.value = '✅ Conectado a ${result.device.platformName}';
      debugPrint('========================================');
      debugPrint('✅ CONEXIÓN COMPLETA Y LISTA PARA USAR');
      debugPrint('  - Hueso Char: ${_huesoCharacteristic != null}');
      debugPrint('  - Servo Char: ${_servoCharacteristic != null}');
      debugPrint('========================================');

      _deviceStateSubscription?.cancel();
      _deviceStateSubscription = _connectedDevice!.connectionState.listen((
        state,
      ) {
        debugPrint('📡 Estado conexión cambiado: $state');
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('⚠️ Dispositivo desconectado');
          _resetConnection();
        }
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error de conexión: $e');
      _connectionStatus.value = '❌ Error: $e';
      _resetConnection();
      return false;
    }
  }

  Future<bool> _discoverCharacteristics() async {
    if (_connectedDevice == null) {
      debugPrint('❌ No hay dispositivo conectado');
      return false;
    }

    try {
      debugPrint('=== DESCUBRIENDO SERVICIOS ===');

      // Descubrir todos los servicios
      final services = await _connectedDevice!.discoverServices();
      debugPrint('📋 Total servicios encontrados: ${services.length}');

      // Listar todos los servicios para depuración
      for (int i = 0; i < services.length; i++) {
        final service = services[i];
        debugPrint('  📦 Servicio ${i + 1}: ${service.uuid.toString()}');

        for (final characteristic in service.characteristics) {
          debugPrint(
            '     🔧 Característica: ${characteristic.uuid.toString()}',
          );
          debugPrint('        Propiedades: ${characteristic.properties}');
        }
      }

      // Buscar nuestro servicio (contiene '00ff')
      BluetoothService? targetService;
      for (final service in services) {
        final String serviceUuid = service.uuid.toString().toLowerCase();
        debugPrint('🔍 Analizando servicio: $serviceUuid');

        // Buscar UUID que contenga '00ff'
        if (serviceUuid.contains('00ff')) {
          targetService = service;
          debugPrint('  ✅ ¡SERVICIO ENCONTRADO! UUID: $serviceUuid');
          break;
        }
      }

      if (targetService == null) {
        debugPrint(
          '❌ ERROR: No se encontró el servicio con UUID que contenga "00ff"',
        );
        debugPrint('   Verifica que el ESP32 tenga el servicio UUID 0x00FF');
        return false;
      }

      // Buscar características dentro del servicio
      debugPrint('=== BUSCANDO CARACTERÍSTICAS ===');

      for (final characteristic in targetService.characteristics) {
        final String charUuid = characteristic.uuid.toString().toLowerCase();
        debugPrint('  📍 Analizando: $charUuid');

        // Buscar característica HUESO (contiene 'ff01')
        if (charUuid.contains('ff01')) {
          _huesoCharacteristic = characteristic;
          debugPrint(
            '    ✅ CARACTERÍSTICA HUESO ENCONTRADA! (UUID: $charUuid)',
          );
          debugPrint('       Propiedades: ${characteristic.properties}');
        }
        // Buscar característica SERVO (contiene 'ff02')
        else if (charUuid.contains('ff02')) {
          _servoCharacteristic = characteristic;
          debugPrint(
            '    ✅ CARACTERÍSTICA SERVO ENCONTRADA! (UUID: $charUuid)',
          );
          debugPrint('       Propiedades: ${characteristic.properties}');
        }
      }

      // Verificar resultados
      if (_huesoCharacteristic == null) {
        debugPrint(
          '❌ ERROR: No se encontró característica HUESO (UUID esperado: ff01)',
        );
      }
      if (_servoCharacteristic == null) {
        debugPrint(
          '❌ ERROR: No se encontró característica SERVO (UUID esperado: ff02)',
        );
      }

      final success =
          (_huesoCharacteristic != null && _servoCharacteristic != null);

      if (success) {
        debugPrint('✅ Todas las características configuradas correctamente');
      } else {
        debugPrint('❌ Faltan características por descubrir');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error en descubrimiento: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    debugPrint('🔌 Desconectando...');
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
    debugPrint('🔄 Estado de conexión reiniciado');
  }

  // ============================================================
  // ENVÍO DE COMANDOS
  // ============================================================

  Future<void> sendHuesoCommand(int huesoId) async {
    debugPrint('📤 sendHuesoCommand llamado - ID: $huesoId');
    debugPrint('   Conectado: ${_isConnected.value}');
    debugPrint(
      '   Característica HUESO disponible: ${_huesoCharacteristic != null}',
    );

    if (!_isConnected.value) {
      debugPrint('❌ No hay conexión Bluetooth activa');
      throw StateError('No hay conexión Bluetooth activa');
    }

    if (_huesoCharacteristic == null) {
      debugPrint('❌ Característica HUESO no disponible');
      throw StateError(
        'Característica HUESO no disponible. ¿El ESP32 está conectado?',
      );
    }

    final value = huesoId.clamp(1, 22);
    debugPrint(
      '📤 Enviando valor: [$value] a característica: ${_huesoCharacteristic!.uuid}',
    );

    try {
      await _huesoCharacteristic!.write([value], withoutResponse: false);
      debugPrint('✅ Comando HUESO enviado correctamente (ID: $value)');
    } catch (e) {
      debugPrint('❌ Error enviando comando HUESO: $e');
      rethrow;
    }
  }

  Future<void> sendServoCommand(int angle) async {
    debugPrint('📤 sendServoCommand llamado - Ángulo: $angle');
    debugPrint('   Conectado: ${_isConnected.value}');
    debugPrint(
      '   Característica SERVO disponible: ${_servoCharacteristic != null}',
    );

    if (!_isConnected.value) {
      debugPrint('❌ No hay conexión Bluetooth activa');
      throw StateError('No hay conexión Bluetooth activa');
    }

    if (_servoCharacteristic == null) {
      debugPrint('❌ Característica SERVO no disponible');
      throw StateError('Característica SERVO no disponible');
    }

    final value = angle.clamp(0, 180);
    debugPrint('📤 Enviando valor: [$value] grados');

    try {
      await _servoCharacteristic!.write([value], withoutResponse: false);
      debugPrint('✅ Comando SERVO enviado correctamente ($value°)');
    } catch (e) {
      debugPrint('❌ Error enviando comando SERVO: $e');
      rethrow;
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    _scanResultsController.close();
    _isScanningController.close();
    _connectionStatus.dispose();
    _isConnected.dispose();
    debugPrint('♻️ BleService liberado');
  }
}
