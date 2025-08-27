import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/health_id_model.dart';
import '../models/medication_model.dart';

class HealthIdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's health ID
  Future<HealthIdModel?> getHealthId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('health_ids')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return null;

      final healthId = HealthIdModel.fromFirestore(doc.docs.first);
      print('Retrieved Health ID - Age: ${healthId.age}');
      return healthId;
    } catch (e) {
      print('Error getting health ID: $e');
      return null;
    }
  }

  // Create or update health ID
  Future<HealthIdModel?> saveHealthId(HealthIdModel healthId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      print('Saving Health ID - Original Age: ${healthId.age}');

      // Update medications from medication collection
      final medications = await _getActiveMedications(user.uid);
      final updatedHealthId = healthId.copyWith(
        activeMedications: medications,
        updatedAt: DateTime.now(),
      );

      print('Saving Health ID - Updated Age: ${updatedHealthId.age}');

      if (healthId.id == null) {
        // Create new health ID
        final docRef = await _firestore
            .collection('health_ids')
            .add(updatedHealthId.toFirestore());

        final savedHealthId = updatedHealthId.copyWith(id: docRef.id);
        print('Created new Health ID - Saved Age: ${savedHealthId.age}');
        return savedHealthId;
      } else {
        // Update existing health ID
        await _firestore
            .collection('health_ids')
            .doc(healthId.id)
            .update(updatedHealthId.toFirestore());

        print('Updated existing Health ID - Saved Age: ${updatedHealthId.age}');
        return updatedHealthId;
      }
    } catch (e) {
      print('Error saving health ID: $e');
      return null;
    }
  }

  // Get active medications for the user
  Future<List<String>> _getActiveMedications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('medications')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MedicationModel.fromFirestore(doc))
          .where((med) => med.isActiveAndNotExpired)
          .map((med) => '${med.name} - ${med.dosage}')
          .toList();
    } catch (e) {
      print('Error getting active medications: $e');
      return [];
    }
  }

  // Generate QR code data string
  String generateQRCodeData(HealthIdModel healthId) {
    return jsonEncode(healthId.toQRData());
  }

  // Generate QR code widget
  QrImageView generateQRCode(HealthIdModel healthId, {double size = 200}) {
    final qrData = jsonEncode(healthId.toQRData());
    
    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  // Save QR code to gallery
  Future<bool> saveQRCodeToGallery(HealthIdModel healthId) async {
    try {
      // For now, we'll just share the QR code instead of saving to gallery
      await shareQRCode(healthId);
      return true;
    } catch (e) {
      print('Error saving QR code: $e');
      return false;
    }
  }

  // Share health ID summary
  Future<void> shareHealthId(HealthIdModel healthId) async {
    try {
      final summary = healthId.generateSummary();
      await Share.share(summary, subject: 'Digital Health ID - ${healthId.name}');
    } catch (e) {
      print('Error sharing health ID: $e');
    }
  }

  // Share QR code
  Future<void> shareQRCode(HealthIdModel healthId) async {
    try {
      final qrData = jsonEncode(healthId.toQRData());
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
        gapless: true,
      );

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/health_id_qr.png';
      
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      qrPainter.paint(canvas, Size(400, 400));
      
      final picture = recorder.endRecording();
      final image = await picture.toImage(400, 400);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      await Share.shareXFiles([XFile.fromData(bytes, name: 'health_id_qr.png')], 
          subject: 'Digital Health ID QR Code - ${healthId.name}');
    } catch (e) {
      print('Error sharing QR code: $e');
    }
  }

  // Get blood group options
  List<String> getBloodGroupOptions() {
    return [
      'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
    ];
  }

  // Get common allergies
  List<String> getCommonAllergies() {
    return [
      'Penicillin',
      'Sulfa drugs',
      'Aspirin',
      'Ibuprofen',
      'Codeine',
      'Morphine',
      'Latex',
      'Peanuts',
      'Tree nuts',
      'Milk',
      'Eggs',
      'Soy',
      'Wheat',
      'Fish',
      'Shellfish',
      'Dust',
      'Pollen',
      'Pet dander',
      'Mold',
      'Bee stings',
    ];
  }
} 