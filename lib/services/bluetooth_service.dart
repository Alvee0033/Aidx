import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as flutter_blue;
import 'package:medigay/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  // Singleton pattern
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();
  
  // Device state
  flutter_blue.BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  
  // Health metrics
  int _heartRate = 0;
  int _spo2 = 0;
  
  // Streams
  final _heartRateController = StreamController<int>.broadcast();
  final _spo2Controller = StreamController<int>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  
  // Subscriptions
  StreamSubscription<List<flutter_blue.ScanResult>>? _scanSubscription;
  StreamSubscription<flutter_blue.BluetoothConnectionState>? _deviceStateSubscription;
  List<StreamSubscription>? _characteristicSubscriptions = [];
  
  // Getters
  Stream<int> get heartRateStream => _heartRateController.stream;
  Stream<int> get spo2Stream => _spo2Controller.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  
  bool get isConnected => _connectedDevice != null;
  bool get isScanning => _isScanning;
  flutter_blue.BluetoothDevice? get connectedDevice => _connectedDevice;
  int get heartRate => _heartRate;
  int get spo2 => _spo2;
  
  // Check permissions
  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    
    return !statuses.values.any((status) => !status.isGranted);
  }
  
  // Start scanning for devices
  Future<void> startScan() async {
    if (_isScanning) return;
    
    if (!await checkPermissions()) {
      debugPrint('Bluetooth permissions not granted');
      return;
    }
    
    _isScanning = true;
    
    // Start scanning
    _scanSubscription = flutter_blue.FlutterBluePlus.scanResults.listen((results) {
      // Nothing to do here, the caller will use FlutterBluePlus.scanResults
    });
    
    await flutter_blue.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    
    // Stop scanning after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      stopScan();
    });
  }
  
  // Stop scanning
  Future<void> stopScan() async {
    if (!_isScanning) return;
    
    _scanSubscription?.cancel();
    await flutter_blue.FlutterBluePlus.stopScan();
    _isScanning = false;
  }
  
  // Connect to a device
  Future<bool> connectToDevice(flutter_blue.BluetoothDevice device) async {
    if (_connectedDevice != null) {
      await disconnectFromDevice();
    }
    
    _connectedDevice = device;
    
    try {
      await device.connect();
      
      _deviceStateSubscription = device.connectionState.listen((state) {
        if (state == flutter_blue.BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
        
        _connectionStateController.add(state == flutter_blue.BluetoothConnectionState.connected);
      });
      
      // Discover services
      List<flutter_blue.BluetoothService> services = await device.discoverServices();
      _processServices(services);
      
      return true;
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      _handleDisconnect();
      return false;
    }
  }
  
  // Disconnect from device
  Future<void> disconnectFromDevice() async {
    if (_connectedDevice == null) return;
    
    _cancelCharacteristicSubscriptions();
    _deviceStateSubscription?.cancel();
    
    try {
      await _connectedDevice!.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
    
    _handleDisconnect();
  }
  
  // Handle disconnect event
  void _handleDisconnect() {
    _connectedDevice = null;
    _heartRate = 0;
    _spo2 = 0;
    
    _heartRateController.add(0);
    _spo2Controller.add(0);
    _connectionStateController.add(false);
  }
  
  // Cancel characteristic subscriptions
  void _cancelCharacteristicSubscriptions() {
    for (var subscription in _characteristicSubscriptions ?? []) {
      subscription.cancel();
    }
    _characteristicSubscriptions = [];
  }
  
  // Process discovered services
  void _processServices(List<flutter_blue.BluetoothService> services) {
    _cancelCharacteristicSubscriptions();
    
    for (var service in services) {
      // Heart rate service
      if (service.uuid.toString().toLowerCase() == AppConstants.heartRateServiceUuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() == AppConstants.heartRateMeasurementCharUuid) {
            // Subscribe to heart rate measurements
            final subscription = characteristic.value.listen((value) {
              if (value.isNotEmpty) {
                // Heart rate is typically in the second byte for most BLE devices
                _heartRate = value.length > 1 ? value[1] : 0;
                _heartRateController.add(_heartRate);
              }
            });
            
            // Enable notifications
            characteristic.setNotifyValue(true);
            _characteristicSubscriptions?.add(subscription);
          }
        }
      }
      
      // Pulse oximeter service
      if (service.uuid.toString().toLowerCase() == AppConstants.pulseOximeterServiceUuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() == AppConstants.spo2MeasurementCharUuid) {
            // Subscribe to SpO2 measurements
            final subscription = characteristic.value.listen((value) {
              if (value.isNotEmpty) {
                _spo2 = value[0];
                _spo2Controller.add(_spo2);
              }
            });
            
            // Enable notifications
            characteristic.setNotifyValue(true);
            _characteristicSubscriptions?.add(subscription);
          }
        }
      }
    }
  }
  
  // Dispose resources
  void dispose() {
    _scanSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    _cancelCharacteristicSubscriptions();
    
    _heartRateController.close();
    _spo2Controller.close();
    _connectionStateController.close();
  }
} 