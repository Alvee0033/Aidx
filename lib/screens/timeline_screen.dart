import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:medigay/utils/theme.dart';
import 'package:medigay/widgets/glass_container.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({Key? key}) : super(key: key);

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<Map<String, dynamic>> _timelineEvents = [];
  bool _isLoading = true;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  void initState() {
    super.initState();
    _loadTimelineEvents();
  }
  
  Future<void> _loadTimelineEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not signed in');
      }

      final uid = user.uid;
      final List<Map<String, dynamic>> events = [];

      // Fetch medications
      final medsSnap = await _firestore
          .collection('medications')
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in medsSnap.docs) {
        final data = doc.data();
        events.add({
          'id': doc.id,
          'title': data['name'] ?? 'Medication',
          'description':
              '${data['dosage'] ?? ''} ${data['frequency'] ?? ''}\n${data['instructions'] ?? ''}',
          'date': _toDate(data['startDate'] ?? data['createdAt']),
          'type': 'medication',
          'doctor': data['doctor'] ?? '',
        });
      }

      // Fetch medical records
      final recordSnap = await _firestore
          .collection('medical_records')
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in recordSnap.docs) {
        final data = doc.data();
        events.add({
          'id': doc.id,
          'title': data['diagnosis'] ?? 'Medical Record',
          'description': data['notes'] ?? data['hospital'] ?? '',
          'date': _toDate(data['date'] ?? data['createdAt']),
          'type': 'diagnosis',
          'doctor': data['doctor'] ?? '',
        });
      }

      // Fetch appointments
      final appointSnap = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in appointSnap.docs) {
        final data = doc.data();
        events.add({
          'id': doc.id,
          'title': data['title'] ?? 'Appointment',
          'description': data['notes'] ?? '',
          'date': _toDate(data['date'] ?? data['createdAt']),
          'type': 'appointment',
          'doctor': data['doctor'] ?? '',
        });
      }

      // Sort events by date descending
      events.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      setState(() {
        _timelineEvents = events;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading timeline: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Color _getEventColor(String type) {
    switch (type) {
      case 'diagnosis':
        return AppTheme.dangerColor;
      case 'medication':
        return AppTheme.primaryColor;
      case 'appointment':
        return AppTheme.accentColor;
      case 'test':
        return Colors.purpleAccent;
      case 'consultation':
        return AppTheme.warningColor;
      default:
        return AppTheme.textMuted;
    }
  }
  
  IconData _getEventIcon(String type) {
    switch (type) {
      case 'diagnosis':
        return Icons.medical_services;
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.calendar_today;
      case 'test':
        return Icons.science;
      case 'consultation':
        return Icons.people;
      default:
        return Icons.event_note;
    }
  }

  // Helper to safely convert Firestore Timestamp or DateTime to DateTime
  DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

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
            'Medical Timeline',
            style: TextStyle(
              color: AppTheme.textTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timelineEvents.isEmpty
              ? const Center(child: Text('No timeline events found'))
              : ListView.builder(
                  itemCount: _timelineEvents.length,
                  itemBuilder: (context, index) {
                    final event = _timelineEvents[index];
                    final isFirst = index == 0;
                    final isLast = index == _timelineEvents.length - 1;
                    final eventColor = _getEventColor(event['type']);
                    final eventIcon = _getEventIcon(event['type']);
                    
                    return TimelineTile(
                      alignment: TimelineAlign.manual,
                      lineXY: 0.2,
                      isFirst: isFirst,
                      isLast: isLast,
                      indicatorStyle: IndicatorStyle(
                        width: 40,
                        height: 40,
                        indicator: Container(
                          decoration: BoxDecoration(
                            color: eventColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            eventIcon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      beforeLineStyle: LineStyle(
                          color: Colors.white.withOpacity(0.1),
                        thickness: 2,
                      ),
                      afterLineStyle: LineStyle(
                          color: Colors.white.withOpacity(0.1),
                        thickness: 2,
                      ),
                      startChild: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(event['date']),
                                style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                  color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(event['date']),
                              style: TextStyle(
                                fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                        endChild: GlassContainer(
                        padding: const EdgeInsets.all(16),
                          backgroundColor: AppTheme.bgGlassLight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: eventColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    event['type'][0].toUpperCase() + event['type'].substring(1),
                                    style: TextStyle(
                                      color: eventColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                  color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                              if (event['description'] != null && event['description'].toString().isNotEmpty)
                            Text(
                              event['description'],
                              style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 8),
                              if (event['doctor'] != null && event['doctor'].toString().isNotEmpty)
                            Row(
                              children: [
                                    const Icon(
                                  Icons.person,
                                  size: 16,
                                      color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event['doctor'],
                                      style: const TextStyle(
                                        color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.refresh),
          onPressed: _loadTimelineEvents,
        ),
      ),
    );
  }
} 