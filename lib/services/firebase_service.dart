import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String healthDataCollection = 'health_data';
  static const String medicationsCollection = 'medications';
  static const String appointmentsCollection = 'appointments';
  static const String remindersCollection = 'reminders';
  static const String symptomsCollection = 'symptoms';
  static const String hospitalsCollection = 'hospitals';
  static const String pharmaciesCollection = 'pharmacies';
  static const String wearableDataCollection = 'wearable_data';
  static const String emergencyContactsCollection = 'emergency_contacts';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // User Profile Management
  Future<void> createUserProfile(String userId, Map<String, dynamic> userData) async {
    await _firestore.collection(usersCollection).doc(userId).set({
      'profile': {
        'name': userData['name'] ?? '',
        'email': userData['email'] ?? '',
        'phone': userData['phone'] ?? '',
        'dateOfBirth': userData['dateOfBirth'],
        'gender': userData['gender'] ?? '',
        'bloodType': userData['bloodType'] ?? '',
        'height': userData['height'],
        'weight': userData['weight'],
        'photo': userData['photo'] ?? '',
        'emergencyContact': userData['emergencyContact'] ?? '',
        'allergies': userData['allergies'] ?? [],
        'medicalConditions': userData['medicalConditions'] ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'preferences': {
        'notifications': true,
        'locationServices': true,
        'dataSharing': false,
        'theme': 'system',
        'language': 'en',
      },
      'subscription': {
        'plan': 'free',
        'expiresAt': null,
        'features': ['basic_health_tracking', 'medication_reminders'],
      }
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore.collection(usersCollection).doc(userId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    final Map<String, dynamic> data = {};
    
    // Update profile fields
    if (updates.containsKey('profile')) {
      data['profile'] = updates['profile'];
      data['profile.updatedAt'] = FieldValue.serverTimestamp();
    }
    
    // Update preferences
    if (updates.containsKey('preferences')) {
      data['preferences'] = updates['preferences'];
    }
    
    await _firestore.collection(usersCollection).doc(userId).update(data);
    notifyListeners();
  }

  // Health Data Management
  Future<void> addHealthData(String userId, Map<String, dynamic> healthData) async {
    await _firestore.collection(healthDataCollection).add({
      'userId': userId,
      'type': healthData['type'], // 'blood_pressure', 'heart_rate', 'temperature', etc.
      'value': healthData['value'],
      'unit': healthData['unit'],
      'timestamp': healthData['timestamp'] ?? FieldValue.serverTimestamp(),
      'source': healthData['source'] ?? 'manual', // 'manual', 'wearable', 'doctor'
      'notes': healthData['notes'] ?? '',
    });
  }

  Stream<QuerySnapshot> getHealthDataStream(String userId, {String? type}) {
    Query query = _firestore
        .collection(healthDataCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);
    
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    
    return query.snapshots();
  }

  // Medication Management
  Future<void> addMedication(String userId, Map<String, dynamic> medication) async {
    await _firestore.collection(medicationsCollection).add({
      'userId': userId,
      'name': medication['name'],
      'dosage': medication['dosage'],
      'frequency': medication['frequency'],
      'startDate': medication['startDate'],
      'endDate': medication['endDate'],
      'instructions': medication['instructions'] ?? '',
      'prescribedBy': medication['prescribedBy'] ?? '',
      'pharmacy': medication['pharmacy'] ?? '',
      'isActive': medication['isActive'] ?? true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMedicationsStream(String userId) {
    return _firestore
        .collection(medicationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateMedication(String medicationId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(medicationsCollection).doc(medicationId).update(updates);
  }

  Future<void> deleteMedication(String medicationId) async {
    await _firestore.collection(medicationsCollection).doc(medicationId).delete();
  }

  // Appointment Management
  Future<void> addAppointment(String userId, Map<String, dynamic> appointment) async {
    await _firestore.collection(appointmentsCollection).add({
      'userId': userId,
      'title': appointment['title'],
      'description': appointment['description'] ?? '',
      'dateTime': appointment['dateTime'],
      'duration': appointment['duration'] ?? 60, // minutes
      'location': appointment['location'] ?? '',
      'doctor': appointment['doctor'] ?? '',
      'type': appointment['type'] ?? 'general', // 'general', 'specialist', 'emergency'
      'status': appointment['status'] ?? 'scheduled', // 'scheduled', 'confirmed', 'completed', 'cancelled'
      'reminderTime': appointment['reminderTime'], // minutes before appointment
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAppointmentsStream(String userId) {
    return _firestore
        .collection(appointmentsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: false)
        .snapshots();
  }

  // Reminder Management
  Future<void> addReminder(String userId, Map<String, dynamic> reminder) async {
    await _firestore.collection(remindersCollection).add({
      'userId': userId,
      'title': reminder['title'],
      'description': reminder['description'] ?? '',
      'type': reminder['type'], // 'medication', 'appointment', 'exercise', 'custom'
      'dateTime': reminder['dateTime'],
      'frequency': reminder['frequency'] ?? 'once', // 'once', 'daily', 'weekly', 'monthly'
      'isActive': reminder['isActive'] ?? true,
      'relatedId': reminder['relatedId'], // ID of related medication/appointment
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getRemindersStream(String userId) {
    return _firestore
        .collection(remindersCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('dateTime', descending: false)
        .snapshots();
  }

  Future<void> updateReminder(String reminderId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(remindersCollection).doc(reminderId).update(updates);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _firestore.collection(remindersCollection).doc(reminderId).delete();
  }

  Future<void> toggleReminderStatus(String reminderId, bool isActive) async {
    await _firestore.collection(remindersCollection).doc(reminderId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Symptom Tracking
  Future<void> addSymptom(String userId, Map<String, dynamic> symptom) async {
    await _firestore.collection(symptomsCollection).add({
      'userId': userId,
      'name': symptom['name'],
      'severity': symptom['severity'], // 1-10 scale
      'description': symptom['description'] ?? '',
      'location': symptom['location'] ?? '',
      'duration': symptom['duration'] ?? '',
      'triggers': symptom['triggers'] ?? [],
      'reliefMethods': symptom['reliefMethods'] ?? [],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getSymptomsStream(String userId) {
    return _firestore
        .collection(symptomsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Emergency Contacts
  Future<void> addEmergencyContact(String userId, Map<String, dynamic> contact) async {
    await _firestore.collection(emergencyContactsCollection).add({
      'userId': userId,
      'name': contact['name'],
      'relationship': contact['relationship'] ?? '',
      'phone': contact['phone'],
      'email': contact['email'] ?? '',
      'isPrimary': contact['isPrimary'] ?? false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getEmergencyContactsStream(String userId) {
    try {
      return _firestore
          .collection(emergencyContactsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('isPrimary', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error creating emergency contacts stream: $e');
      // Return empty stream on error
      return Stream.empty();
    }
  }

  Future<void> updateEmergencyContact(String contactId, Map<String, dynamic> updates) async {
    await _firestore.collection(emergencyContactsCollection).doc(contactId).update(updates);
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    await _firestore.collection(emergencyContactsCollection).doc(contactId).delete();
  }

  // SOS Events
  Future<void> addSosEvent(String userId, Map<String, dynamic> sosData) async {
    await _firestore.collection('sos_events').add({
      'userId': userId,
      'type': sosData['type'], // 'manual', 'auto'
      'triggeredAt': FieldValue.serverTimestamp(),
      'location': sosData['location'], // GeoPoint
      'vitals': sosData['vitals'] ?? {}, // heart_rate, spo2, etc.
      'emergencyContacts': sosData['emergencyContacts'] ?? [],
      'status': sosData['status'] ?? 'triggered', // 'triggered', 'cancelled', 'dispatched'
      'cancelledAt': sosData['cancelledAt'],
      'dispatchedAt': sosData['dispatchedAt'],
      'notes': sosData['notes'] ?? '',
    });
  }

  Stream<QuerySnapshot> getSosEventsStream(String userId) {
    return _firestore
        .collection('sos_events')
        .where('userId', isEqualTo: userId)
        .orderBy('triggeredAt', descending: true)
        .snapshots();
  }

  Future<void> updateSosEvent(String eventId, Map<String, dynamic> updates) async {
    await _firestore.collection('sos_events').doc(eventId).update(updates);
  }

  // User SOS Settings
  Future<void> saveSosSettings(String userId, Map<String, dynamic> settings) async {
    await _firestore.collection(usersCollection).doc(userId).update({
      'sosSettings': {
        'autoSosEnabled': settings['autoSosEnabled'] ?? false,
        'heartRateThreshold': settings['heartRateThreshold'] ?? 100,
        'spo2Threshold': settings['spo2Threshold'] ?? 95,
        'abnormalDurationSeconds': settings['abnormalDurationSeconds'] ?? 30,
        'primaryEmergencyContact': settings['primaryEmergencyContact'],
        'emergencyNumber': settings['emergencyNumber'] ?? '112',
        'locationSharing': settings['locationSharing'] ?? true,
        'updatedAt': FieldValue.serverTimestamp(),
      }
    });
  }

  Future<Map<String, dynamic>?> getSosSettings(String userId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('sosSettings')) {
        final settings = doc.data()!['sosSettings'];
        if (settings is Map<String, dynamic>) {
          return settings;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting SOS settings: $e');
      return null;
    }
  }

  // Wearable Data
  Future<void> addWearableData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection(wearableDataCollection).add({
      'userId': userId,
      'deviceId': data['deviceId'],
      'deviceType': data['deviceType'], // 'smartwatch', 'fitness_tracker', 'heart_monitor'
      'dataType': data['dataType'], // 'heart_rate', 'steps', 'sleep', 'blood_oxygen'
      'value': data['value'],
      'unit': data['unit'],
      'timestamp': FieldValue.serverTimestamp(),
      'batteryLevel': data['batteryLevel'],
      'isConnected': data['isConnected'] ?? true,
    });
  }

  Stream<QuerySnapshot> getWearableDataStream(String userId, {String? dataType}) {
    Query query = _firestore
        .collection(wearableDataCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);
    
    if (dataType != null) {
      query = query.where('dataType', isEqualTo: dataType);
    }
    
    return query.snapshots();
  }

  // Hospital and Pharmacy Data (for nearby search)
  Future<void> addHospital(Map<String, dynamic> hospital) async {
    await _firestore.collection(hospitalsCollection).add({
      'name': hospital['name'],
      'address': hospital['address'],
      'phone': hospital['phone'] ?? '',
      'website': hospital['website'] ?? '',
      'specialties': hospital['specialties'] ?? [],
      'rating': hospital['rating'] ?? 0.0,
      'location': GeoPoint(hospital['latitude'], hospital['longitude']),
      'isOpen24Hours': hospital['isOpen24Hours'] ?? false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addPharmacy(Map<String, dynamic> pharmacy) async {
    await _firestore.collection(pharmaciesCollection).add({
      'name': pharmacy['name'],
      'address': pharmacy['address'],
      'phone': pharmacy['phone'] ?? '',
      'website': pharmacy['website'] ?? '',
      'services': pharmacy['services'] ?? [],
      'rating': pharmacy['rating'] ?? 0.0,
      'location': GeoPoint(pharmacy['latitude'], pharmacy['longitude']),
      'isOpen24Hours': pharmacy['isOpen24Hours'] ?? false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Search nearby hospitals/pharmacies
  Future<QuerySnapshot> searchNearbyHospitals(double latitude, double longitude, double radiusKm) async {
    // Note: This is a simplified search. For production, consider using Firebase GeoFirestore
    return await _firestore
        .collection(hospitalsCollection)
        .get();
  }

  Future<QuerySnapshot> searchNearbyPharmacies(double latitude, double longitude, double radiusKm) async {
    return await _firestore
        .collection(pharmaciesCollection)
        .get();
  }

  // Analytics and Reports
  Future<Map<String, dynamic>> getUserHealthSummary(String userId) async {
    // Get health data for the last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final healthData = await _firestore
        .collection(healthDataCollection)
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThan: thirtyDaysAgo)
        .get();

    final medications = await _firestore
        .collection(medicationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final appointments = await _firestore
        .collection(appointmentsCollection)
        .where('userId', isEqualTo: userId)
        .where('dateTime', isGreaterThan: DateTime.now())
        .get();

    return {
      'healthDataCount': healthData.docs.length,
      'activeMedications': medications.docs.length,
      'upcomingAppointments': appointments.docs.length,
      'lastHealthCheck': healthData.docs.isNotEmpty ? healthData.docs.first.data()['timestamp'] : null,
    };
  }

  // Data Export
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final userProfile = await getUserProfile(userId);
    final healthData = await _firestore
        .collection(healthDataCollection)
        .where('userId', isEqualTo: userId)
        .get();
    final medications = await _firestore
        .collection(medicationsCollection)
        .where('userId', isEqualTo: userId)
        .get();
    final appointments = await _firestore
        .collection(appointmentsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    return {
      'profile': userProfile,
      'healthData': healthData.docs.map((doc) => doc.data()).toList(),
      'medications': medications.docs.map((doc) => doc.data()).toList(),
      'appointments': appointments.docs.map((doc) => doc.data()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // Cleanup and maintenance
  Future<void> deleteUserData(String userId) async {
    // Delete all user data (for GDPR compliance)
    final collections = [
      healthDataCollection,
      medicationsCollection,
      appointmentsCollection,
      remindersCollection,
      symptomsCollection,
      wearableDataCollection,
      emergencyContactsCollection,
    ];

    for (String collection in collections) {
      final docs = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in docs.docs) {
        await doc.reference.delete();
      }
    }

    // Delete user profile
    await _firestore.collection(usersCollection).doc(userId).delete();
  }

  // Drug management
  Future<void> addDrug(String name, String dosage, String frequency, String time) async {
    if (currentUser == null) return;
    
    await _firestore.collection('users').doc(currentUser!.uid).collection('drugs').add({
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'time': time,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getDrugs() async {
    if (currentUser == null) return [];
    
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('drugs')
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  Future<void> deleteDrug(String drugId) async {
    if (currentUser == null) return;
    
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('drugs')
        .doc(drugId)
        .delete();
  }

  // Symptom record management (for AI analysis)
  Future<void> saveSymptomRecord(String userId, Map<String, dynamic> recordData) async {
    await _firestore.collection('users').doc(userId).collection('symptomRecords').add({
      ...recordData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getSymptomHistory(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('symptomRecords')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
} 