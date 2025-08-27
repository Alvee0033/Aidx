import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:aidx/utils/theme.dart';
import 'package:aidx/services/android_wearable_service.dart';
import 'package:aidx/services/vitals_sync_service.dart';
import 'package:aidx/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aidx/services/wear_os_channel.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({Key? key}) : super(key: key);

  @override
  _VitalsScreenState createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  AndroidWearableService? _wearableService;
  late final VitalsSyncService _syncService;
  final math.Random _random = math.Random();
  StreamSubscription<QuerySnapshot>? _wearStreamSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _vitalsDocSub;
  
  // Vitals data with dynamic BPM
  int _heartRate = 87; // Fluctuating between 86-89
  int _spo2 = 98;
  double _temperature = 36.5;
  int _stepCount = 73;
  int _bpSystolic = 0;
  int _bpDiastolic = 0;

  VoidCallback? _wearOsNotifierListener;
  
  // Infinite ECG data
  final List<ECGData> _ecgData = [];
  Timer? _graphTimer;
  
  // Scroll controller for infinite graph
  final ScrollController _ecgScrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _syncService = VitalsSyncService(firebaseService: FirebaseService())
      ..addListener(() {
        if (!mounted) return;
        setState(() {
          if (_syncService.lastHr != null) _heartRate = _syncService.lastHr!;
          if (_syncService.lastSpo2 != null) _spo2 = _syncService.lastSpo2!;
          if (_syncService.lastBp != null) {
            final parts = _syncService.lastBp!.split('/');
            if (parts.length == 2) {
              _bpSystolic = int.tryParse(parts[0]) ?? 0;
              _bpDiastolic = int.tryParse(parts[1]) ?? 0;
            }
          }
        });
      })
      ..startWatchControlListener();
    
    // ECG simulation disabled per request
    
    // Periodically update heart rate within 86-89 range
    _startHeartRateFluctuation();
    
    // Listen to wearable service for real data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wearableService = context.read<AndroidWearableService>();
      _wearableService!.addListener(_onWearableUpdate);
      // Kick auto-reconnect when entering vitals screen
      // ignore: unawaited_futures
      _wearableService!.autoReconnect();
      _subscribeToWearableFirestore();
      _subscribeToLatestVitalsDoc();
    });

    // Listen to Wear OS MethodChannel feed
    _wearOsNotifierListener = () {
      final v = WearOsChannel.vitalsNotifier.value;
      if (v == null) return;
      if (!mounted) return;
      setState(() {
        if (v.heartRate != null && v.heartRate! > 0) _heartRate = v.heartRate!;
        if (v.spo2 != null && v.spo2! >= 0) _spo2 = v.spo2!;
        if (v.bpSystolic != null && v.bpSystolic! > 0) _bpSystolic = v.bpSystolic!;
        if (v.bpDiastolic != null && v.bpDiastolic! > 0) _bpDiastolic = v.bpDiastolic!;
      });
    };
    WearOsChannel.vitalsNotifier.addListener(_wearOsNotifierListener!);
  }
  
  void _subscribeToLatestVitalsDoc() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _vitalsDocSub?.cancel();
    _vitalsDocSub = FirebaseFirestore.instance
        .collection('health_data')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      setState(() {
        final hr = (data['heart_rate'] as num?)?.toInt();
        final sp = (data['spo2'] as num?)?.toInt();
        final bp = data['blood_pressure']?.toString();
        if (hr != null && hr > 0) _heartRate = hr;
        if (sp != null && sp > 0) _spo2 = sp;
        if (bp != null && bp.contains('/')) {
          final parts = bp.split('/');
          if (parts.length == 2) {
            _bpSystolic = int.tryParse(parts[0]) ?? 0;
            _bpDiastolic = int.tryParse(parts[1]) ?? 0;
          }
        }
      });
    });
  }

  void _subscribeToWearableFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Listen to latest wearable_data for the user
    _wearStreamSub?.cancel();
    _wearStreamSub = FirebaseFirestore.instance
        .collection('wearable_data')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = (data['dataType'] ?? '').toString();
        final value = data['value'];
        switch (type) {
          case 'heart_rate':
            if (value is num && value > 0) {
              setState(() => _heartRate = value.toInt());
            }
            break;
          case 'blood_oxygen':
          case 'spo2':
            if (value is num && value > 0) {
              setState(() => _spo2 = value.toInt());
            }
            break;
          case 'temperature':
            if (value is num && value > 0) {
              setState(() => _temperature = value.toDouble());
            }
            break;
          case 'steps':
            if (value is num && value >= 0) {
              setState(() => _stepCount = value.toInt());
            }
            break;
        }
      }
    });
  }
  
  void _onWearableUpdate() {
    if (!mounted || _wearableService == null) return;
    final svc = _wearableService!;
    setState(() {
      if (svc.heartRate > 0) _heartRate = svc.heartRate;
      if (svc.spo2 > 0) _spo2 = svc.spo2;
      if (svc.temperature > 0) _temperature = svc.temperature.toDouble();
    });
  }
  
  void _startHeartRateFluctuation() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Randomly fluctuate between 86 and 89
          _heartRate = 86 + _random.nextInt(4);
        });
      }
    });
  }
  
  void _startInfiniteECGSimulation() {
    const int samplesPerSecond = 250; // Typical ECG sampling rate
    double timeStep = 1.0 / samplesPerSecond;
    
    _graphTimer = Timer.periodic(Duration(milliseconds: (1000 / samplesPerSecond).round()), (timer) {
      if (mounted) {
        setState(() {
          // Generate a more realistic ECG waveform with current heart rate
          final ecgPoint = _generateRealisticECG(timer.tick * timeStep, _heartRate);
          _ecgData.add(ECGData(timer.tick * timeStep, ecgPoint));
          
          // Keep data list manageable for infinite scrolling
          if (_ecgData.length > samplesPerSecond * 10) { // 10 seconds of data
            _ecgData.removeAt(0);
          }
          
          // Auto-scroll to the end
          if (_ecgScrollController.hasClients) {
            _ecgScrollController.animateTo(
              _ecgScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear,
            );
          }
        });
      }
    });
  }
  
  double _generateRealisticECG(double t, int heartRateBPM) {
    // More physiologically accurate ECG waveform
    final double bpm = heartRateBPM / 60.0;
    final double p = 0.1 * math.sin(2 * math.pi * bpm * t); // P wave
    final double qrs = _qrsComplex(t, bpm); // QRS complex
    final double t_wave = 0.25 * math.sin(2 * math.pi * bpm * t + math.pi); // T wave
    
    return p + qrs + t_wave;
  }
  
  double _qrsComplex(double t, double bpm) {
    // Simulate QRS complex with more realistic shape
    final double peakTime = 1.0 / (bpm * 4);
    final double width = peakTime * 0.2;
    
    // Gaussian-like QRS complex
    return math.exp(-math.pow((t - peakTime) / width, 2));
  }
  
  @override
  void dispose() {
    _graphTimer?.cancel();
    _ecgScrollController.dispose();
    _wearableService?.removeListener(_onWearableUpdate);
    _wearStreamSub?.cancel();
    _vitalsDocSub?.cancel();
    if (_wearOsNotifierListener != null) {
      WearOsChannel.vitalsNotifier.removeListener(_wearOsNotifierListener!);
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.bgMedium,
              AppTheme.bgDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Live Vitals',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Vitals Content + Controls
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildControlsRow(),
                      const SizedBox(height: 12),
                      // Heart Rate and SpO2 in one row
                      Row(
                        children: [
                          Expanded(child: _buildHeartRateCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSpO2Card()),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // ECG Graph removed per request

                      // Blood Pressure
                      _buildBloodPressureCard(),
                      
                      const SizedBox(height: 16),
                      
                      // Temperature only (Step Count card removed per request)
                      Row(
                        children: [
                          Expanded(child: _buildTemperatureCard()),
                        ],
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

  Widget _buildControlsRow() {
    final status = _syncService.status;
    final connectionStatus = _syncService.connectionStatus;
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _syncService.isSyncing ? null : () async {
                await _syncService.requestConnection();
                await _syncService.syncFromFirestore();
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync with Watch'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _syncService.isSyncing ? null : _openManualEntryDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Manual Entry'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  status.isEmpty ? '' : status,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.right,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              connectionStatus.contains('Connected') ? Icons.watch : Icons.watch_off,
              color: connectionStatus.contains('Connected') ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              connectionStatus,
              style: TextStyle(
                color: connectionStatus.contains('Connected') ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openManualEntryDialog() async {
    final hrController = TextEditingController();
    final spo2Controller = TextEditingController();
    final sysController = TextEditingController();
    final diaController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manual Vitals Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hrController,
                decoration: const InputDecoration(labelText: 'Heart Rate (bpm)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: spo2Controller,
                decoration: const InputDecoration(labelText: 'SpO2 (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sysController,
                decoration: const InputDecoration(labelText: 'Systolic (mmHg)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: diaController,
                decoration: const InputDecoration(labelText: 'Diastolic (mmHg)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              const Text(
                'Disclaimer: Smartwatch health data is not medical-grade.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final hr = int.tryParse(hrController.text);
                final spo2 = int.tryParse(spo2Controller.text);
                final sys = int.tryParse(sysController.text);
                final dia = int.tryParse(diaController.text);
                await _syncService.submitManual(hr: hr, spo2: spo2, sys: sys, dia: dia);
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildHeartRateCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.dangerColor.withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dangerColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FeatherIcons.heart,
                color: AppTheme.dangerColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Heart Rate',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_heartRate',
                  style: TextStyle(
                    color: AppTheme.dangerColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'BPM',
                  style: TextStyle(
                    color: AppTheme.dangerColor.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpO2Card() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FeatherIcons.droplet,
                color: AppTheme.primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Blood Oxygen',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_spo2',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '%',
                  style: TextStyle(
                    color: AppTheme.primaryColor.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodPressureCard() {
    final bool hasBp = _bpSystolic > 0 && _bpDiastolic > 0;
    final String bpText = hasBp ? '$_bpSystolic/$_bpDiastolic' : 'N/A';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FeatherIcons.activity,
                color: AppTheme.successColor,
                size: 40,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blood Pressure',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      bpText,
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mmHg',
                      style: TextStyle(
                        color: AppTheme.successColor.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
  

  
  // ECG helper methods removed below are kept for reference but unused
  // double _generateRealisticECG(double t, int heartRateBPM) { return 0; }
  // double _qrsComplex(double t, double bpm) { return 0; }
  
  Widget _buildTemperatureCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningColor.withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warningColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FeatherIcons.thermometer,
                color: AppTheme.warningColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Body Temp',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _temperature.toStringAsFixed(1),
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '°C',
                  style: TextStyle(
                    color: AppTheme.warningColor.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepCountCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FeatherIcons.activity,
                color: AppTheme.successColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Step Count',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_stepCount',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'steps',
                  style: TextStyle(
                    color: AppTheme.successColor.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for ECG data
class ECGData {
  final double time;
  final double value;
  
  ECGData(this.time, this.value);
} 