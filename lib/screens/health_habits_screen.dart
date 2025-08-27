import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/health_habit_service.dart';
import '../services/notification_service.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../utils/theme.dart';

class HealthHabitsScreen extends StatefulWidget {
  const HealthHabitsScreen({Key? key}) : super(key: key);

  @override
  State<HealthHabitsScreen> createState() => _HealthHabitsScreenState();
}

class _HealthHabitsScreenState extends State<HealthHabitsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final HealthHabitService _habitService = HealthHabitService();
  final NotificationService _notificationService = NotificationService();
  
  List<Map<String, dynamic>> _habits = [];
  List<Map<String, dynamic>> _completedHabits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _habitService.initializeTTS();
    _loadHabits();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _notifications.initialize(initializationSettings);
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Get completed habits for today
      final completedSnapshot = await _firestore
          .collection('health_habits')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayStart.add(const Duration(days: 1))))
          .get();

      _completedHabits = completedSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading habits: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markHabitCompleted(String habitType, String habitName) async {
    final ok = await _habitService.markHabitCompleted(habitType);
    if (ok) {
      await _loadHabits();
      _showSnackBar('Habit completed successfully! 🎉', isError: false);
    } else {
      _showSnackBar('Already completed today or error', isError: true);
    }
  }

  Future<void> _showNotification(String title, String body) async {
    await _notificationService.showNotification(title: title, body: body);
  }

  // Schedule a daily reminder at a given time (local notification)
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    final now = DateTime.now();
    final scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute)
        .add(const Duration(days: 0));
    await _notificationService.scheduleRecurringNotification(
      title: 'Daily Habit Reminder',
      body: 'Don\'t forget to complete your habits today!',
      scheduledTime: scheduled.isAfter(now) ? scheduled : scheduled.add(const Duration(days: 1)),
      frequency: 'daily',
    );
    _showSnackBar('Daily reminder scheduled at ${time.format(context)}');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isHabitCompleted(String habitType) {
    return _completedHabits.any((habit) => habit['habitType'] == habitType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.8),
                    AppTheme.accentColor.withOpacity(0.6),
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Health Habits',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_active, color: Colors.white),
                    tooltip: 'Schedule daily reminder',
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (!mounted) return;
                      if (picked != null) {
                        await scheduleDailyReminder(picked);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadHabits,
                  ),
                ],
              ),
            ),

            // Progress Section
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Today\'s Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_completedHabits.length} of 8 habits completed',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      Text(
                        '${((_completedHabits.length / 8) * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _completedHabits.length / 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ],
              ),
            ),

            // Habits Grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _getHabitsList().length,
                      itemBuilder: (context, index) {
                        final habit = _getHabitsList()[index];
                        final isCompleted = _isHabitCompleted(habit['type']);
                        
                        return _buildHabitCard(
                          habit: habit,
                          isCompleted: isCompleted,
                          onTap: () => _markHabitCompleted(
                            habit['type'],
                            habit['name'],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getHabitsList() {
    return [
      {
        'type': 'walk',
        'name': 'Walk Today',
        'icon': FeatherIcons.activity,
        'color': Colors.blue,
        'description': 'Take a walk for 30 minutes',
      },
      {
        'type': 'water',
        'name': 'Drink Water',
        'icon': FeatherIcons.droplet,
        'color': Colors.cyan,
        'description': 'Drink 8 glasses of water',
      },
      {
        'type': 'medication',
        'name': 'Take Medication',
        'icon': FeatherIcons.plus,
        'color': Colors.red,
        'description': 'Take your prescribed medication',
      },
      {
        'type': 'exercise',
        'name': 'Exercise',
        'icon': FeatherIcons.zap,
        'color': Colors.orange,
        'description': 'Do some light exercise',
      },
      {
        'type': 'social',
        'name': 'Social Activity',
        'icon': FeatherIcons.users,
        'color': Colors.purple,
        'description': 'Connect with friends/family',
      },
      {
        'type': 'eating',
        'name': 'Healthy Eating',
        'icon': FeatherIcons.heart,
        'color': Colors.green,
        'description': 'Eat a healthy meal',
      },
      {
        'type': 'sleep',
        'name': 'Good Sleep',
        'icon': FeatherIcons.moon,
        'color': Colors.indigo,
        'description': 'Get 7-8 hours of sleep',
      },
      {
        'type': 'mental',
        'name': 'Mental Health',
        'icon': FeatherIcons.smile,
        'color': Colors.pink,
        'description': 'Practice mindfulness',
      },
    ];
  }

  Widget _buildHabitCard({
    required Map<String, dynamic> habit,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCompleted
                ? [
                    habit['color'].withOpacity(0.3),
                    habit['color'].withOpacity(0.1),
                  ]
                : [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? habit['color'].withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? habit['color'].withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? habit['color'].withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      habit['icon'],
                      size: 28,
                      color: isCompleted
                          ? habit['color']
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    habit['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? Colors.white
                          : Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habit['description'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 