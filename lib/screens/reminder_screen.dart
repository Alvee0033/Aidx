import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/glass_container.dart';
import '../utils/theme.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  
  late FirebaseService _firebaseService;
  late NotificationService _notificationService;
  late TabController _tabController;
  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedType = 'medication';
  String _selectedFrequency = 'once';
  List<Map<String, dynamic>> _medications = [];
  bool _isLoadingMedications = false;
  
  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    _notificationService = NotificationService();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedications();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMedications() async {
    setState(() {
      _isLoadingMedications = true;
    });
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final medicationsSnapshot = await _firebaseService.getMedicationsStream(userId).first;
        _medications = medicationsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading medications: $e');
    } finally {
      setState(() {
        _isLoadingMedications = false;
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  Future<void> _addReminder() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both date and time')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }
        
        final DateTime reminderDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        
        // Save to Firestore
        final reminderData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'type': _selectedType,
          'dateTime': reminderDateTime,
          'frequency': _selectedFrequency,
          'isActive': true,
          'dosage': _dosageController.text.isNotEmpty ? _dosageController.text : null,
          'relatedId': null, // Will be set if medication is selected
        };
        
        await _firebaseService.addReminder(userId, reminderData);
        
        // Schedule notification
        await _notificationService.scheduleNotification(
          title: 'Medication Reminder',
          body: 'Time to take your medication',
          scheduledTime: DateTime.now().add(Duration(hours: 1)),
        );
        
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _dosageController.clear();
        _frequencyController.clear();
        _selectedDate = null;
        _selectedTime = null;
        _selectedType = 'medication';
        _selectedFrequency = 'once';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reminder added successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding reminder: ${e.toString()}'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
    Future<void> _saveMedicationAsReminder(Map<String, dynamic> medication) async {
    try {
    setState(() {
      _isLoading = true;
    });
    
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Set default reminder time to 1 hour from now
      final reminderDateTime = DateTime.now().add(const Duration(hours: 1));
      
      final reminderData = {
        'title': 'Take ${medication['name']}',
        'description': 'Uses: ${medication['uses'] ?? 'As prescribed'}',
        'type': 'medication',
        'dateTime': reminderDateTime,
        'frequency': 'once',
        'isActive': true,
        'relatedId': medication['id'],
      };
      
      await _firebaseService.addReminder(userId, reminderData);
      
      // Schedule notification
      await _notificationService.scheduleNotification(
        title: 'Medication Reminder',
        body: 'Time to take your medication',
        scheduledTime: DateTime.now().add(Duration(hours: 1)),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for ${medication['name']}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting reminder: ${e.toString()}'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteMedication(Map<String, dynamic> medication) async {
    try {
      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.bgGlassMedium,
            title: Text(
              'Delete Medication',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete "${medication['name']}" from your saved medications?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textTeal),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.dangerColor),
                ),
              ),
            ],
          );
        },
      );

      if (shouldDelete == true) {
    setState(() {
      _isLoading = true;
    });
    
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await _firebaseService.deleteMedication(medication['id']);
          
          // Refresh the medications list
          await _loadMedications();
      
      ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${medication['name']} deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
      );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting medication: ${e.toString()}'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: SafeArea(
                child: Column(
                  children: [
              // Navigation Bar
              Container(
                margin: const EdgeInsets.all(8),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.alarm, color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Medication Reminders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: GlassContainer(
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Add Reminder'),
                      Tab(text: 'Saved Medications'),
                      Tab(text: 'Upcoming'),
                    ],
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Add New Reminder Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: GlassContainer(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.add_alarm, color: AppTheme.textTeal, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                'Add New Reminder',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Reminder Type
                              DropdownButtonFormField<String>(
                                value: _selectedType,
                                style: TextStyle(color: Colors.white),
                                dropdownColor: AppTheme.bgDarkSecondary,
                                decoration: InputDecoration(
                                  labelText: 'Reminder Type',
                                  labelStyle: TextStyle(color: AppTheme.textTeal),
                                  prefixIcon: Icon(Icons.category, color: AppTheme.textTeal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppTheme.primaryColor),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.bgGlassMedium,
                                ),
                                items: [
                                  DropdownMenuItem(value: 'medication', child: Text('Medication', style: TextStyle(color: Colors.white))),
                                  DropdownMenuItem(value: 'appointment', child: Text('Appointment', style: TextStyle(color: Colors.white))),
                                  DropdownMenuItem(value: 'exercise', child: Text('Exercise', style: TextStyle(color: Colors.white))),
                                  DropdownMenuItem(value: 'custom', child: Text('Custom', style: TextStyle(color: Colors.white))),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Title
                              TextFormField(
                                controller: _titleController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Title',
                                  labelStyle: TextStyle(color: AppTheme.textTeal),
                                  prefixIcon: Icon(Icons.title, color: AppTheme.textTeal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppTheme.primaryColor),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.bgGlassMedium,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Description
                              TextFormField(
                                controller: _descriptionController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  labelStyle: TextStyle(color: AppTheme.textTeal),
                                  prefixIcon: Icon(Icons.description, color: AppTheme.textTeal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppTheme.primaryColor),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.bgGlassMedium,
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              
                              // Dosage (for medication type)
                              if (_selectedType == 'medication') ...[
                                TextFormField(
                                  controller: _dosageController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Dosage',
                                    labelStyle: TextStyle(color: AppTheme.textTeal),
                                    prefixIcon: Icon(Icons.medication, color: AppTheme.textTeal),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: AppTheme.primaryColor),
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.bgGlassMedium,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              
                              // Date and Time Row
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectDate(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.bgGlassMedium,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today, color: AppTheme.textTeal),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selectedDate != null 
                                                  ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                                                  : 'Select Date',
                                              style: TextStyle(
                                                color: _selectedDate != null ? Colors.white : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectTime(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.bgGlassMedium,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.access_time, color: AppTheme.textTeal),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selectedTime != null 
                                                  ? _selectedTime!.format(context)
                                                  : 'Select Time',
                                              style: TextStyle(
                                                color: _selectedTime != null ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Frequency
                              DropdownButtonFormField<String>(
                                value: _selectedFrequency,
                                style: TextStyle(color: Colors.white),
                                dropdownColor: AppTheme.bgDarkSecondary,
                                decoration: InputDecoration(
                                  labelText: 'Frequency',
                                  labelStyle: TextStyle(color: AppTheme.textTeal),
                                  prefixIcon: Icon(Icons.repeat, color: AppTheme.textTeal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppTheme.primaryColor),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.bgGlassMedium,
                                ),
                                items: [
                                  DropdownMenuItem(value: 'once', child: Text('Once', style: TextStyle(color: Colors.white))),
                                  DropdownMenuItem(value: 'daily', child: Text('Daily', style: TextStyle(color: Colors.white))),
                                  DropdownMenuItem(value: 'weekly', child: Text('Weekly', style: TextStyle(color: Colors.white))),
                                  DropdownMenuItem(value: 'monthly', child: Text('Monthly', style: TextStyle(color: Colors.white))),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedFrequency = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              // Add Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _addReminder,
                                  child: _isLoading
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Adding...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_alarm, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                    'Add Reminder',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
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
                    ),
                    
                    // Saved Medications Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.medication, color: AppTheme.textTeal, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Saved Medications',
                      style: TextStyle(
                                    fontSize: 18,
                        fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Set reminders for your saved medications',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            if (_isLoadingMedications)
                              const Center(
                                child: CircularProgressIndicator(),
                              )
                            else if (_medications.isEmpty)
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.medication_outlined,
                                      size: 48,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No saved medications',
                                style: TextStyle(
                                  fontSize: 16,
                                        color: Colors.white.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Save medications from the drug screen to set reminders',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._medications.map((medication) => Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.bgGlassMedium,
                                      AppTheme.bgGlassMedium.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      // Medication Icon
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [AppTheme.primaryColor, AppTheme.accentColor],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.medication,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Medication Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              medication['name'] ?? 'Unknown Medication',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              medication['uses'] ?? 'No uses specified',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.8),
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Action Buttons
                                      Column(
                                        children: [
                                          // Set Reminder Button
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [AppTheme.accentColor, AppTheme.primaryColor],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.accentColor.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: _isLoading ? null : () => _saveMedicationAsReminder(medication),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.alarm_add, color: Colors.white, size: 16),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Set Reminder',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Delete Button
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.dangerColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppTheme.dangerColor.withOpacity(0.3)),
                                            ),
                                            child: IconButton(
                                              onPressed: () => _deleteMedication(medication),
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: AppTheme.dangerColor,
                                                size: 20,
                                              ),
                                              tooltip: 'Delete Medication',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )).toList(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Upcoming Reminders Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: GlassContainer(
                        child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                            Row(
                              children: [
                                Icon(Icons.schedule, color: AppTheme.textTeal, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Upcoming Reminders',
                                            style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firebaseService.getRemindersStream(
                                FirebaseAuth.instance.currentUser?.uid ?? '',
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Text(
                                    'Error loading reminders: ${snapshot.error}',
                                    style: TextStyle(color: AppTheme.dangerColor),
                                  );
                                }
                                
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                
                                final reminders = snapshot.data?.docs ?? [];
                                
                                if (reminders.isEmpty) {
                                  return Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.alarm_off,
                                          size: 48,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No reminders scheduled',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white.withOpacity(0.7),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add a reminder to get started',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                return Column(
                                  children: reminders.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final dateTime = (data['dateTime'] as Timestamp).toDate();
                                    final isOverdue = dateTime.isBefore(DateTime.now());
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isOverdue 
                                              ? [AppTheme.dangerColor.withOpacity(0.1), AppTheme.dangerColor.withOpacity(0.05)]
                                              : [AppTheme.bgGlassMedium, AppTheme.bgGlassMedium.withOpacity(0.8)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isOverdue 
                                              ? AppTheme.dangerColor.withOpacity(0.3)
                                              : Colors.white.withOpacity(0.1),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _getTypeColor(data['type'] ?? 'custom').withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _getTypeIcon(data['type'] ?? 'custom'),
                                                color: _getTypeColor(data['type'] ?? 'custom'),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    data['title'] ?? 'Untitled',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (data['description'] != null && 
                                                      data['description'].isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                                    Text(
                                                      data['description'],
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.7),
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.event,
                                            size: 14,
                                                        color: AppTheme.textTeal,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('MMM dd, yyyy').format(dateTime),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white.withOpacity(0.7),
                                          ),
                                                      ),
                                                      const SizedBox(width: 12),
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                                        color: AppTheme.textTeal,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('h:mm a').format(dateTime),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white.withOpacity(0.7),
                                                        ),
                                                      ),
                                                      if (isOverdue) ...[
                                                        const SizedBox(width: 12),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.dangerColor,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            'OVERDUE',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                        ],
                                      ),
                                    ],
                                  ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: AppTheme.dangerColor,
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                // Delete reminder logic
                                                try {
                                                  await FirebaseFirestore.instance
                                                      .collection('reminders')
                                                      .doc(doc.id)
                                                      .delete();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Reminder deleted'),
                                                      backgroundColor: AppTheme.successColor,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error deleting reminder: $e'),
                                                      backgroundColor: AppTheme.dangerColor,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Color _getTypeColor(String type) {
    switch (type) {
      case 'medication':
        return AppTheme.primaryColor;
      case 'appointment':
        return AppTheme.accentColor;
      case 'exercise':
        return AppTheme.successColor;
      default:
        return AppTheme.textTeal;
    }
  }
  
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.event;
      case 'exercise':
        return Icons.fitness_center;
      default:
        return Icons.alarm;
    }
  }
} 