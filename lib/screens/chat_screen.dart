import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.bgGlassLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FeatherIcons.arrowLeft, color: AppTheme.textTeal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FeatherIcons.messageCircle, color: AppTheme.textTeal, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: const Text(
                'AI Health Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textTeal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
            icon: const Icon(FeatherIcons.logOut, size: 16, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon
                AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnimation, _floatAnimation]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.3),
                                AppTheme.accentColor.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                                                     child: Icon(
                             FeatherIcons.settings,
                             size: 60,
                             color: AppTheme.primaryColor,
                           ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Maintenance Title
                Text(
                  '🛠️ Under Maintenance',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'AI Health Chat Assistant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Description
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'We\'re currently upgrading our AI chat system to provide you with even better health assistance.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Our team is working hard to bring you:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem('🎯 Enhanced AI responses'),
                      _buildFeatureItem('🔒 Improved privacy & security'),
                      _buildFeatureItem('📱 Better mobile experience'),
                      _buildFeatureItem('⚡ Faster response times'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Estimated Time
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.2),
                        AppTheme.accentColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FeatherIcons.clock,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Estimated completion: 2-3 days',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Alternative Options
                Text(
                  'In the meantime, you can:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildAlternativeOption(
                  icon: FeatherIcons.activity,
                  title: 'Use Symptom Detector',
                  description: 'Get AI-powered symptom analysis',
                  onTap: () => Navigator.pushNamed(context, '/symptom'),
                ),
                
                const SizedBox(height: 12),
                
                _buildAlternativeOption(
                  icon: FeatherIcons.bookOpen,
                  title: 'Check Drug Information',
                  description: 'Search for medication details',
                  onTap: () => Navigator.pushNamed(context, '/drug'),
                ),
                
                const SizedBox(height: 12),
                
                _buildAlternativeOption(
                  icon: FeatherIcons.mapPin,
                  title: 'Find Nearby Hospitals',
                  description: 'Locate healthcare facilities',
                  onTap: () => Navigator.pushNamed(context, '/hospital'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
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
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              FeatherIcons.arrowRight,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 