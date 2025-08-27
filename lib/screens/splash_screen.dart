import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aidx/services/auth_service.dart';
import 'package:aidx/screens/auth/login_screen.dart';
import 'package:aidx/screens/dashboard_screen.dart';
import 'package:aidx/utils/theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:aidx/utils/constants.dart';
import 'package:aidx/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  String _statusMessage = 'Initializing...';
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 SplashScreen initState called');
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    
    _controller.forward();
    
    // Set a fast timeout to ensure we don't get stuck on splash screen
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('⚠️ Splash screen timeout - forcing navigation to login');
      if (mounted && _isLoading) {
        _forceNavigateToLogin();
      }
    });
    
    // Kick initialization immediately after first frame to avoid build blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }
  
  void _forceNavigateToLogin() {
    debugPrint('🔄 Force navigating to login screen due to timeout');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
    }
  }
  
  Future<void> _initializeApp() async {
    try {
      debugPrint('🔄 Checking authentication status');
      _updateStatus('Checking login status...');
      await _checkAuthAndNavigate();
    } catch (e) {
      debugPrint('❌ Error in splash screen initialization: $e');
      _setError('Initialization failed: $e');
      // Force navigation to login after error
      _forceNavigateToLogin();
    }
  }
  
  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }
  
  void _setError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _checkAuthAndNavigate() async {
    try {
      if (!mounted) return;
      
      // If a background trigger requested opening SOS, route there first
      final prefs = await SharedPreferences.getInstance();
      final bool openSos = prefs.getBool('pending_open_sos') ?? false;
      if (openSos) {
        await prefs.setBool('pending_open_sos', false);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppConstants.routeSos);
        setState(() { _isLoading = false; });
        return;
      }

      // Ensure permissions are requested visibly at launch
      await _ensurePermissionsAtLaunch();
      
      AuthService? authService;
      try {
        authService = Provider.of<AuthService>(context, listen: false);
        debugPrint('✅ AuthService retrieved successfully');
      } catch (e) {
        debugPrint('❌ Error getting AuthService: $e');
        throw Exception('Failed to get AuthService: $e');
      }
      
      final bool isLoggedIn = authService.isLoggedIn;
      debugPrint('🔄 Auth check - isLoggedIn: $isLoggedIn');
      
      if (isLoggedIn) {
        debugPrint('✅ User is logged in, navigating to dashboard');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppConstants.routeDashboard);
      } else {
        debugPrint('ℹ️ User is not logged in, navigating to login screen');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error checking auth status: $e');
      _setError('Authentication check failed: $e');
      // Force navigation to login after error
      _forceNavigateToLogin();
    }
  }

  Future<void> _ensurePermissionsAtLaunch() async {
    // Cancel splash timeout while we handle permissions
    _timeoutTimer?.cancel();
    
    // First request all needed permissions
    await _requestMinimalPermissions();
    
    // Then ask separately for special permissions
    await _promptBatteryRestrictionPermission();
    await _promptDrawOverAppsPermission();
    await _promptBackgroundProcessPermission();
    
    // If still missing, prompt to open settings or continue
    bool allGranted = await _areAllCriticalPermissionsGranted();
    if (!allGranted && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Permissions needed'),
            content: const Text('To enable all AidX features (SOS, wearables, calls, alerts), please grant the requested permissions.'),
            actions: [
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () async {
                  await _requestMinimalPermissions();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _requestMinimalPermissions() async {
    debugPrint('📱 Requesting all necessary permissions');
    // Cancel splash timeout while permission dialogs are shown
    _timeoutTimer?.cancel();
    
    try {
      // Request all essential permissions for the app to function properly
      
      // Request notification permission (most important)
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        debugPrint('📱 Requesting notification permission');
        await Permission.notification.request();
      }
      
      // Request location permissions (essential for SOS and location-based features)
      try {
      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        debugPrint('📱 Requesting location permission');
          await Permission.location.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Location permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
        
        final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
        if (!locationWhenInUseStatus.isGranted) {
          debugPrint('📱 Requesting location when in use permission');
          await Permission.locationWhenInUse.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Location when in use permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Location permission request failed: $e');
        // Continue without location permission
      }
      
      // Request camera permission (for QR scanning, AI vision features)
      try {
        final cameraStatus = await Permission.camera.status;
        if (!cameraStatus.isGranted) {
          debugPrint('📱 Requesting camera permission');
          await Permission.camera.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Camera permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Camera permission request failed: $e');
      }
      
      // Request microphone permission (for voice features, AI video calls)
      try {
        final microphoneStatus = await Permission.microphone.status;
        if (!microphoneStatus.isGranted) {
          debugPrint('📱 Requesting microphone permission');
          await Permission.microphone.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Microphone permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Microphone permission request failed: $e');
      }
      
      // Request storage permissions (for saving health data, images)
      try {
        final storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          debugPrint('📱 Requesting storage permission');
          await Permission.storage.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Storage permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Storage permission request failed: $e');
      }
      
      // Request bluetooth permissions (for wearable devices)
      try {
        final bluetoothStatus = await Permission.bluetooth.status;
        if (!bluetoothStatus.isGranted) {
          debugPrint('📱 Requesting bluetooth permission');
          await Permission.bluetooth.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Bluetooth permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
        
        final bluetoothScanStatus = await Permission.bluetoothScan.status;
        if (!bluetoothScanStatus.isGranted) {
          debugPrint('📱 Requesting bluetooth scan permission');
          await Permission.bluetoothScan.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Bluetooth scan permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
        
        final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
        if (!bluetoothConnectStatus.isGranted) {
          debugPrint('📱 Requesting bluetooth connect permission');
          await Permission.bluetoothConnect.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Bluetooth connect permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Bluetooth permission request failed: $e');
      }
      
      // Request phone permission (for emergency calls)
      try {
        final phoneStatus = await Permission.phone.status;
        if (!phoneStatus.isGranted) {
          debugPrint('📱 Requesting phone permission');
          await Permission.phone.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Phone permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Phone permission request failed: $e');
      }
      
      // Request sensor permissions (for health monitoring)
      try {
        final sensorsStatus = await Permission.sensors.status;
        if (!sensorsStatus.isGranted) {
          debugPrint('📱 Requesting sensors permission');
          await Permission.sensors.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Sensors permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Sensors permission request failed: $e');
      }
      
      // Request battery optimization permission (for background services)
      try {
        final batteryOptimizationStatus = await Permission.ignoreBatteryOptimizations.status;
        if (!batteryOptimizationStatus.isGranted) {
          debugPrint('📱 Requesting battery optimization permission');
          await Permission.ignoreBatteryOptimizations.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Battery optimization permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Battery optimization permission request failed: $e');
      }
      
      // Request background processes permission (for health monitoring)
      try {
        final backgroundProcessesStatus = await Permission.ignoreBatteryOptimizations.status;
        if (!backgroundProcessesStatus.isGranted) {
          debugPrint('📱 Requesting background processes permission');
          await Permission.ignoreBatteryOptimizations.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Background processes permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Background processes permission request failed: $e');
      }
      
      // Request system alert window permission (for emergency notifications and draw over apps)
      try {
        final systemAlertWindowStatus = await Permission.systemAlertWindow.status;
        if (!systemAlertWindowStatus.isGranted) {
          debugPrint('📱 Requesting system alert window permission (draw over apps)');
          await Permission.systemAlertWindow.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ System alert window permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ System alert window permission request failed: $e');
      }
      
      // Request exact alarm permission (for precise notifications)
      try {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (!exactAlarmStatus.isGranted) {
          debugPrint('📱 Requesting exact alarm permission');
          await Permission.scheduleExactAlarm.request().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Exact alarm permission request timed out');
              return PermissionStatus.denied;
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Exact alarm permission request failed: $e');
      }
      
      debugPrint('✅ All permissions requested successfully');
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      // Don't block the app if permissions fail
    }
  }

  Future<void> _promptBatteryRestrictionPermission() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted && mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Allow background activity'),
            content: const Text('To monitor health data and send alerts reliably, allow AidX to run without battery restrictions.'),
            actions: [
              TextButton(
                onPressed: () async {
                  await Permission.ignoreBatteryOptimizations.request();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Allow'),
              ),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Skip'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Battery restriction prompt error: $e');
    }
  }

  Future<void> _promptDrawOverAppsPermission() async {
    try {
      final status = await Permission.systemAlertWindow.status;
      if (!status.isGranted && mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Allow “Draw over other apps”'),
            content: const Text('AidX uses overlay to show urgent health alerts on top of other apps.'),
            actions: [
              TextButton(
                onPressed: () async {
                  await Permission.systemAlertWindow.request();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Allow'),
              ),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Skip'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Draw over apps prompt error: $e');
    }
  }

  Future<void> _promptBackgroundProcessPermission() async {
    try {
      // There is no distinct Android runtime dialog for generic background processing.
      // We guide users to allow battery optimization exception as a proxy.
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted && mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Allow background processes'),
            content: const Text('To keep services running (SOS monitoring, wearable sync), allow AidX to run in background.'),
            actions: [
              TextButton(
                onPressed: () async {
                  await Permission.ignoreBatteryOptimizations.request();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Allow'),
              ),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Skip'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Background processes prompt error: $e');
    }
  }

  Future<bool> _areAllCriticalPermissionsGranted() async {
    try {
      final List<Permission> permissions = [
        Permission.notification,
        Permission.location,
        Permission.locationWhenInUse,
        Permission.camera,
        Permission.microphone,
        Permission.storage,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.phone,
        Permission.sensors,
        Permission.ignoreBatteryOptimizations,
        Permission.systemAlertWindow,
        Permission.scheduleExactAlarm,
      ];
      final List<PermissionStatus> statuses = await Future.wait(
        permissions.map((p) => p.status),
      );
      bool isOk(PermissionStatus s) => s.isGranted || s.isLimited;
      return statuses.every(isOk);
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timeoutTimer?.cancel();
    debugPrint('🔄 SplashScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 SplashScreen build called');
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.bgGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.bgGlassLight,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppTheme.primaryColor,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                // App name
                const Text(
                  'AidX',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                const Text(
                  'Your Personal Health Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Status message
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Loading indicator or error
                if (_isLoading)
                  const SpinKitPulse(
                    color: AppTheme.primaryColor,
                    size: 50.0,
                  )
                else if (_hasError)
                  Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _hasError = false;
                          });
                          _initializeApp();
                        },
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _forceNavigateToLogin,
                        child: const Text('Skip to Login'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 