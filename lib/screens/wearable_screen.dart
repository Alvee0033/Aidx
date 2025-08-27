import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:aidx/utils/theme.dart';
import 'package:aidx/utils/constants.dart';
import 'package:aidx/widgets/glass_container.dart';
import 'package:aidx/services/database_init.dart';
import 'package:aidx/services/android_wearable_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class WearableScreen extends StatefulWidget {
  const WearableScreen({super.key});

  @override
  State<WearableScreen> createState() => _WearableScreenState();
}

class _WearableScreenState extends State<WearableScreen> {
  // Android Wearable Service
  final AndroidWearableService _androidService = AndroidWearableService();
  
  // Database service
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Connected devices from database
  List<Map<String, dynamic>> _connectedDevices = [];
  Map<String, dynamic>? _currentDevice;
  
  // Timer for simulated data (fallback)
  Timer? _simulationTimer;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initializeAndroidService();
    _loadConnectedDevices();
    // No simulation; show only real wearable data
  }
  
  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    
    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });
    
    if (!allGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth and location permissions are required for Android smartwatch connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _initializeAndroidService() async {
    await _androidService.initialize();
    
    // Listen to service changes
    _androidService.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  void _startScan() async {
    await _androidService.startScan();
  }
  
  void _stopScan() {
    _androidService.stopScan();
  }
  
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _androidService.connectToDevice(device);
  }
  
  Future<void> _disconnectFromDevice() async {
    await _androidService.disconnect();
  }
  
  void _startSimulation() {}

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.bgGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppTheme.bgGlassLight,
          elevation: 0,
          title: const Text(
            'Android Smartwatch Connect',
            style: TextStyle(
              color: AppTheme.textTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textTeal),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Health Metrics Card
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.watch, color: AppTheme.primaryColor, size: 24),
                                const SizedBox(width: 8),
                                const Text(
                                  "Android Smartwatch Vitals",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Metrics Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    icon: Icons.favorite,
                                    value: _androidService.heartRate.toString(),
                                    unit: "BPM",
                                    color: Colors.red,
                                    isActive: _androidService.isConnected,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMetricCard(
                                    icon: Icons.water_drop,
                                    value: _androidService.spo2.toString(),
                                    unit: "%",
                                    color: Colors.blue,
                                    isActive: _androidService.isConnected,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Additional metrics for Android smartwatch
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    icon: Icons.directions_walk,
                                    value: _androidService.steps.toString(),
                                    unit: "Steps",
                                    color: Colors.green,
                                    isActive: _androidService.isConnected,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMetricCard(
                                    icon: Icons.battery_full,
                                    value: "${_androidService.batteryLevel.round()}%",
                                    unit: "Battery",
                                    color: Colors.orange,
                                    isActive: _androidService.isConnected,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Blood Pressure and Temperature
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    icon: Icons.favorite,
                                    value: "${_androidService.bloodPressureSystolic}/${_androidService.bloodPressureDiastolic}",
                                    unit: "mmHg",
                                    color: Colors.purple,
                                    isActive: _androidService.isConnected,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMetricCard(
                                    icon: Icons.thermostat,
                                    value: "${_androidService.temperature}°C",
                                    unit: "Temp",
                                    color: Colors.yellow,
                                    isActive: _androidService.isConnected,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Connection Status
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _androidService.isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _androidService.isConnected ? Colors.green : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _androidService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                                    color: _androidService.isConnected ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _androidService.isConnected 
                                      ? "Connected to ${_androidService.connectedDevice?.name ?? 'Android Smartwatch'}"
                                      : "Not Connected",
                                    style: TextStyle(
                                      color: _androidService.isConnected ? Colors.green : Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Action Buttons
                            if (_androidService.isConnected) ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _androidService.forceSensorReading(),
                                  icon: const Icon(Icons.sensors),
                                  label: const Text("Activate Sensors"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _disconnectFromDevice,
                                  icon: const Icon(Icons.bluetooth_disabled),
                                  label: const Text("Disconnect"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _androidService.isScanning ? null : _startScan,
                                  icon: Icon(_androidService.isScanning ? Icons.hourglass_empty : Icons.bluetooth_searching),
                                  label: Text(_androidService.isScanning ? "Scanning..." : "Scan for Android Smartwatches"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Available Android Smartwatches
                      if (_androidService.isScanning || _androidService.getScanResults().isNotEmpty) ...[
                        const Text(
                          "Paired & Available Smartwatches",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        GlassContainer(
                          child: _androidService.isScanning && _androidService.getScanResults().isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                                                              Text(
                                          "Checking paired smartwatches...",
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _androidService.getScanResults().length,
                                separatorBuilder: (context, index) => Divider(
                                  color: Colors.white.withOpacity(0.1),
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final result = _androidService.getScanResults()[index];
                                  final device = result.device;
                                  final name = device.name.isNotEmpty ? device.name : "Android Smartwatch";
                                  final rssi = result.rssi;
                                  final isAndroidWatch = _androidService.isAndroidSmartwatch(device);
                                  
                                  return ListTile(
                                    leading: Icon(
                                      Icons.watch,
                                      color: isAndroidWatch ? AppTheme.primaryColor : Colors.grey,
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          device.id.id,
                                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                        ),
                                        Text(
                                          "Signal: ${rssi} dBm",
                                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                        ),
                                        if (isAndroidWatch)
                                          Text(
                                            rssi == -50 ? "✅ Paired Device" : "✅ Android Smartwatch Detected",
                                            style: TextStyle(
                                              color: rssi == -50 ? Colors.green : AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: _androidService.isConnecting ? null : () => _connectToDevice(device),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isAndroidWatch ? AppTheme.primaryColor : Colors.grey,
                                      ),
                                      child: Text(
                                        _androidService.isConnecting && _androidService.connectedDevice?.id == device.id
                                            ? "Connecting..."
                                            : "Connect",
                                      ),
                                    ),
                                  );
                                },
                              ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Connected Devices from Database
                      if (_connectedDevices.isNotEmpty) ...[
                        const Text(
                          "Previously Connected Devices",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        GlassContainer(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _connectedDevices.length,
                            separatorBuilder: (context, index) => Divider(
                              color: Colors.white.withOpacity(0.1),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final device = _connectedDevices[index];
                              final isConnected = device['isConnected'] ?? false;
                              
                              return ListTile(
                                leading: Icon(
                                  Icons.watch,
                                  color: isConnected ? Colors.green : AppTheme.textMuted,
                                ),
                                title: Text(
                                  device['deviceName'] ?? 'Unknown Device',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device['deviceId'] ?? '',
                                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                    ),
                                    Text(
                                      isConnected ? 'Connected' : 'Last connected: ${_formatLastConnected(device['lastConnected'])}',
                                      style: TextStyle(
                                        color: isConnected ? Colors.green : Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isConnected ? Colors.green : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeDevice(device['id']),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                      
                      // Instructions for Android Smartwatch
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  "How to Connect Android Smartwatch",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInstructionStep("1", "Pair your Android smartwatch with phone's Bluetooth settings first"),
                            _buildInstructionStep("2", "Make sure your watch is connected to phone"),
                            _buildInstructionStep("3", "Tap 'Scan for Android Smartwatches' to find paired devices"),
                            _buildInstructionStep("4", "Select your watch from the list and tap 'Connect'"),
                            _buildInstructionStep("5", "Your health metrics will update automatically"),
                            _buildInstructionStep("6", "Vitals data is automatically saved to your health profile"),
                            _buildInstructionStep("7", "Supported features: Heart Rate, SpO2, Steps, Battery, Temperature, Blood Pressure"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? color : Colors.white.withOpacity(0.5),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isActive ? color : Colors.white.withOpacity(0.5),
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? color.withOpacity(0.8) : Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadConnectedDevices() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final devices = await _databaseService.getWearableDevices(user.uid);
        setState(() {
          _connectedDevices = devices;
        });
      }
    } catch (e) {
      debugPrint('Error loading connected devices: $e');
    }
  }

  String _formatLastConnected(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else {
        date = DateTime.parse(timestamp.toString());
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _removeDevice(String deviceId) async {
    try {
      await _databaseService.deleteWearableDevice(deviceId);
      await _loadConnectedDevices();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing device: $e')),
      );
    }
  }
}