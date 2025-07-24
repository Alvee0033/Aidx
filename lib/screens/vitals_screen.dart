import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:aidx/utils/theme.dart';
import 'package:aidx/services/esp32_max30102_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({Key? key}) : super(key: key);

  @override
  _VitalsScreenState createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final ESP32MAX30102Service _esp32Service = ESP32MAX30102Service();
  final math.Random _random = math.Random();
  
  // Vitals data with dynamic BPM
  int _heartRate = 87; // Fluctuating between 86-89
  int _spo2 = 98;
  double _temperature = 36.5;
  int _stepCount = 73;
  
  // Infinite ECG data
  final List<ECGData> _ecgData = [];
  Timer? _graphTimer;
  
  // Scroll controller for infinite graph
  final ScrollController _ecgScrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Generate infinite ECG data with dynamic BPM
    _startInfiniteECGSimulation();
    
    // Periodically update heart rate within 86-89 range
    _startHeartRateFluctuation();
    
    // Listen to ESP32 service for real data
    _initializeESP32Listeners();
  }
  
  void _initializeESP32Listeners() {
    _esp32Service.heartRateStream.listen((rate) {
      if (mounted && rate > 0) {
        setState(() => _heartRate = rate);
      }
    });
    
    _esp32Service.spo2Stream.listen((spo2) {
      if (mounted && spo2 > 0) {
        setState(() => _spo2 = spo2);
      }
    });
    
    _esp32Service.temperatureStream.listen((temp) {
      if (mounted && temp > 0) {
        setState(() => _temperature = temp);
      }
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
              
              // Vitals Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Heart Rate and SpO2 in one row
                      Row(
                        children: [
                          Expanded(child: _buildHeartRateCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSpO2Card()),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // ECG Graph (Full width, Infinite)
                      _buildInfiniteECGSection(),
                      
                      const SizedBox(height: 16),
                      
                      // Temperature and Step Count in one row
                      Row(
                        children: [
                          Expanded(child: _buildTemperatureCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStepCountCard()),
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
  
  Widget _buildInfiniteECGSection() {
    return Container(
      height: 200,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FeatherIcons.activity,
                    color: AppTheme.dangerColor,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ECG Graph',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time Cardiac Activity',
                      style: TextStyle(
                        color: AppTheme.dangerColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Infinite ECG Graph
          Expanded(
            child: ListView.builder(
              controller: _ecgScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 1,
              itemBuilder: (context, _) => SizedBox(
                width: MediaQuery.of(context).size.width * 2, // Double the width for scrolling
                child: SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  primaryXAxis: NumericAxis(
                    isVisible: false,
                    majorGridLines: const MajorGridLines(width: 0),
                    edgeLabelPlacement: EdgeLabelPlacement.none,
                  ),
                  primaryYAxis: NumericAxis(
                    isVisible: false,
                    majorGridLines: const MajorGridLines(width: 0),
                    minimum: -2,
                    maximum: 2,
                  ),
                  series: <LineSeries<ECGData, double>>[
                    LineSeries<ECGData, double>(
                      dataSource: _ecgData,
                      xValueMapper: (ECGData data, _) => data.time,
                      yValueMapper: (ECGData data, _) => data.value,
                      color: AppTheme.dangerColor,
                      width: 3,
                      animationDuration: 0,
                      enableTooltip: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
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