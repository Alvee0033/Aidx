import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_drawer.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../services/places_service.dart';
import '../services/free_places_service.dart';
import '../utils/theme.dart';

class ProfessionalsPharmacyScreen extends StatefulWidget {
  const ProfessionalsPharmacyScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalsPharmacyScreen> createState() => _ProfessionalsPharmacyScreenState();
}

class _ProfessionalsPharmacyScreenState extends State<ProfessionalsPharmacyScreen> {
  bool _isLoading = false;
  Position? _currentPosition;
  String _selectedOption = 'doctors'; // 'doctors' or 'pharmacy'
  String _selectedSpecialty = 'orthopedic';
  double _radius = 5.0; // in kilometers
  String _selectedCity = '';
  List<Map<String, dynamic>> _results = [];
  final TextEditingController _cityController = TextEditingController();
  final PlacesService _placesService = PlacesService();
  final FreePlacesService _freePlacesService = FreePlacesService();
  bool _useFreeService = true; // Set to true to use free API (no credit card needed)

  final List<String> _specialties = [
    'orthopedic',
    'gynecologist', 
    'cardiologist',
    'dermatologist',
    'neurologist',
    'psychiatrist',
    'pediatrician',
    'ophthalmologist',
    'dentist',
    'general practitioner'
  ];

  final List<String> _cities = [
    'Dhaka',
    'Chittagong', 
    'Sylhet',
    'Rajshahi',
    'Khulna',
    'Barisal',
    'Rangpur',
    'Mymensingh',
    'Comilla',
    'Narayanganj'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        setState(() {
          _currentPosition = position;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
    }
  }

  Future<void> _searchNearby() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      if (_selectedOption == 'doctors') {
        await _searchDoctors();
      } else {
        await _searchPharmacies();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchDoctors() async {
    final city = _selectedCity.isNotEmpty ? _selectedCity : null;
    final results = _useFreeService 
      ? await _freePlacesService.searchDoctors(
          location: _currentPosition!,
          specialty: _selectedSpecialty,
          radius: _radius,
          city: city,
        )
      : await _placesService.searchDoctors(
          location: _currentPosition!,
          specialty: _selectedSpecialty,
          radius: _radius,
          city: city,
        );
    
    setState(() {
      _results = results;
    });
  }

  Future<void> _searchPharmacies() async {
    final results = _useFreeService
      ? await _freePlacesService.searchPharmacies(
          location: _currentPosition!,
          radius: _radius,
          city: _selectedCity.isNotEmpty ? _selectedCity : null,
        )
      : await _placesService.searchPharmacies(
          location: _currentPosition!,
          radius: _radius,
          city: _selectedCity.isNotEmpty ? _selectedCity : null,
        );
    
    setState(() {
      _results = results;
    });
  }

  Future<void> _launchMaps(double latitude, double longitude, String name) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch maps')),
      );
    }
  }
  
  Future<void> _launchPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  Widget _buildSearchOptions() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Options',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Find nearby healthcare professionals',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Option Selection with improved styling
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                color: AppTheme.bgGlassMedium,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedOption = 'doctors';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: _selectedOption == 'doctors' 
                              ? AppTheme.primaryGradient
                              : null,
                          color: _selectedOption == 'doctors' 
                              ? null 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _selectedOption == 'doctors' ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ] : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medical_services,
                              color: _selectedOption == 'doctors' 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.7),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Find Doctors',
                              style: TextStyle(
                                color: _selectedOption == 'doctors' 
                                    ? Colors.white 
                                    : Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedOption = 'pharmacy';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: _selectedOption == 'pharmacy' 
                              ? AppTheme.primaryGradient
                              : null,
                          color: _selectedOption == 'pharmacy' 
                              ? null 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _selectedOption == 'pharmacy' ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ] : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_pharmacy,
                              color: _selectedOption == 'pharmacy' 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.7),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Find Pharmacy',
                              style: TextStyle(
                                color: _selectedOption == 'pharmacy' 
                                    ? Colors.white 
                                    : Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Specialty Selection (for doctors)
            if (_selectedOption == 'doctors') ...[
              _buildSectionTitle('Specialty'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                dropdownColor: AppTheme.bgDarkSecondary,
                decoration: _buildInputDecoration('Select specialty'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: _specialties.map((specialty) {
                  return DropdownMenuItem(
                    value: specialty,
                    child: Text(specialty.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSpecialty = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              // City Selection for doctors
              _buildSectionTitle('City'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCity.isEmpty ? null : _selectedCity,
                dropdownColor: AppTheme.bgDarkSecondary,
                decoration: _buildInputDecoration('Select city (optional)'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All cities'),
                  ),
                  ..._cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
            
            // City Selection (for pharmacy)
            if (_selectedOption == 'pharmacy') ...[
              _buildSectionTitle('City'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCity.isEmpty ? null : _selectedCity,
                dropdownColor: AppTheme.bgDarkSecondary,
                decoration: _buildInputDecoration('Select city (optional)'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All cities'),
                  ),
                  ..._cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
            
            // Radius Slider with improved styling
            _buildSectionTitle('Search Radius: ${_radius.toStringAsFixed(1)} km'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgGlassMedium,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: AppTheme.accentColor,
                  overlayColor: AppTheme.accentColor.withOpacity(0.2),
                  valueIndicatorColor: AppTheme.primaryColor,
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _radius,
                  min: 1.0,
                  max: 20.0,
                  divisions: 19,
                  onChanged: (value) {
                    setState(() {
                      _radius = value;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Service Toggle with improved styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgGlassMedium,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.info_outline, size: 20, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API Service',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Using ${_useFreeService ? 'Free' : 'Google'} API',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _useFreeService,
                    onChanged: (value) {
                      setState(() {
                        _useFreeService = value;
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  Text(
                    _useFreeService ? 'Free' : 'Google',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _useFreeService ? AppTheme.successColor : AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Search Button with improved styling
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search, size: 24),
                label: Text(
                  'Search ${_selectedOption == 'doctors' ? 'Doctors' : 'Pharmacies'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                ),
                onPressed: _currentPosition != null ? _searchNearby : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      filled: true,
      fillColor: AppTheme.bgGlassMedium,
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final isDoctor = _selectedOption == 'doctors';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: AppTheme.newsGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isDoctor ? Icons.medical_services : Icons.local_pharmacy,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgGlassHeavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: AppTheme.warningColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${result['rating']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Distance badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgGlassHeavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      '${result['distance']} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and specialty
                Text(
                  result['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                if (isDoctor) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${result['specialty'] ?? ''} • ${result['experience'] ?? ''}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result['qualifications'] ?? ''} • ${result['consultation_fee'] ?? ''}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        result['hours'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Address
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        result['address'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Phone
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text(
                      result['phone'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                if (!isDoctor) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Services:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ((result['services'] as List<dynamic>?) ?? [])
                        .map((service) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                service?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: AppTheme.primaryColor),
                          foregroundColor: AppTheme.primaryColor,
                        ),
                        onPressed: () => _launchPhone(result['phone'] ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () => _launchMaps(
                          result['latitude'] ?? 0.0,
                          result['longitude'] ?? 0.0,
                          result['name'] ?? '',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Professionals & Pharmacy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textTeal,
          ),
        ),
        backgroundColor: AppTheme.bgGlassLight,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.primaryColor),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.bgGlassLight,
                AppTheme.bgGlassMedium,
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_currentPosition == null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_off, color: AppTheme.warningColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location access required for nearby search',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warningColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Enable'),
                      ),
                    ],
                  ),
                ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSearchOptions(),
                      
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      else if (_results.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                'Found ${_results.length} ${_selectedOption == 'doctors' ? 'doctors' : 'pharmacies'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._results.map((result) => _buildResultCard(result)).toList(),
                      ] else if (!_isLoading && _results.isEmpty && _currentPosition != null)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search criteria.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
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
            ],
          ),
        ),
      ),
    );
  }
}

 