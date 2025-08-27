# Digital Health ID Feature

## Overview

The Digital Health ID feature provides users with a comprehensive digital health profile that can be shared via QR code or text summary. This feature is particularly useful for elderly users living alone and emergency situations.

## Features

### 🏥 QR Code Generation
- Automatically generates a QR code containing all health information
- QR code can be scanned by medical professionals during emergencies
- Contains structured JSON data with all health details

### 📋 Health Information Management
- **Personal Details**: Name, blood group
- **Medical Information**: Allergies, medical conditions, active medications
- **Emergency Contacts**: Multiple contacts with relationship and contact details
- **Notes**: Additional medical information and notes

### 🔄 Automatic Medication Sync
- Automatically pulls active medications from the medication tracking system
- Updates in real-time when medications are added/removed
- Shows medication name and dosage

### 📤 Sharing Capabilities
- **QR Code Sharing**: Share QR code image via any app
- **Text Summary**: Share formatted text summary of health information
- **Save to Gallery**: Save QR code to device gallery for offline access

### 🎯 Emergency-Ready
- Designed for emergency situations
- Quick access to critical health information
- Contact emergency numbers directly from the app

## Usage

### Creating a Health ID
1. Navigate to Dashboard → "Digital Health ID"
2. Tap "Create Health ID" button
3. Fill in your health information:
   - Basic information (name, blood group)
   - Allergies (select from common list or add custom)
   - Emergency contacts (name, relationship, phone, email)
   - Medical conditions and notes
4. Tap "Save" to create your health ID

### Viewing and Sharing
1. Your health ID will display with:
   - QR code for scanning
   - Complete health information summary
   - Emergency contacts with call buttons
2. Use the menu (⋮) to:
   - Edit health information
   - Share summary text
   - Share QR code image
   - Save QR code to gallery

### QR Code Usage
- Medical professionals can scan the QR code with any QR reader
- The QR code contains structured JSON data with all health information
- Can be used in hospitals, ambulances, or any emergency situation

## Technical Implementation

### Models
- `HealthIdModel`: Main data model for health ID information
- `EmergencyContact`: Model for emergency contact details

### Services
- `HealthIdService`: Handles CRUD operations, QR generation, and sharing

### Screens
- `HealthIdScreen`: Main display screen with QR code and information
- `HealthIdEditScreen`: Form for creating/editing health ID

### Dependencies Added
- `qr_flutter`: QR code generation
- `qr_code_scanner`: QR code scanning (for future features)
- `path_provider`: File system access
- `image_gallery_saver`: Save images to gallery
- `share_plus`: Share functionality

## Data Structure

The QR code contains JSON data with:
```json
{
  "userId": "user_id",
  "name": "Patient Name",
  "bloodGroup": "A+",
  "allergies": ["Penicillin", "Peanuts"],
  "emergencyContacts": [
    {
      "name": "John Doe",
      "relationship": "Spouse",
      "phone": "+1234567890",
      "email": "john@example.com"
    }
  ],
  "activeMedications": ["Aspirin - 100mg", "Metformin - 500mg"],
  "medicalConditions": "Diabetes, Hypertension",
  "notes": "Additional medical notes",
  "lastUpdated": "2024-01-15T10:30:00Z"
}
```

## Security Considerations

- Health data is stored securely in Firebase Firestore
- User authentication required to access health ID
- Data is only accessible to the authenticated user
- QR codes contain sensitive information - users should be cautious when sharing

## Future Enhancements

- QR code scanning to read other health IDs
- Integration with hospital systems
- Emergency contact notifications
- Health ID verification system
- Offline QR code storage
- Multiple language support for health information

## Emergency Use Cases

### For Elderly Users Living Alone
- Display QR code prominently in home
- Share with neighbors or caregivers
- Quick access during medical emergencies

### For Medical Professionals
- Scan QR code to get instant patient information
- Access to allergies, medications, and emergency contacts
- Reduce time to critical information in emergencies

### For Family Members
- Share health ID with family members
- Keep updated emergency contact information
- Quick access to medical history 