import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
    final authService = Provider.of<AuthService>(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    
    return Drawer(
      width: isTablet ? 300 : isDesktop ? 320 : 280,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/icon.png',
                  width: isTablet || isDesktop ? 100 : 80,
                  height: isTablet || isDesktop ? 100 : 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  authService.currentUser?.displayName ?? 'User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet || isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authService.currentUser?.email ?? 'user@example.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTablet || isDesktop ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: AppConstants.routeDashboard,
            isSelected: currentRoute == AppConstants.routeDashboard,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.watch,
            title: 'Wearable',
            route: AppConstants.routeWearable,
            isSelected: currentRoute == AppConstants.routeWearable,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.medication,
            title: 'Medications',
            route: AppConstants.routeDrug,
            isSelected: currentRoute == AppConstants.routeDrug,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.sick,
            title: 'Symptoms',
            route: AppConstants.routeSymptom,
            isSelected: currentRoute == AppConstants.routeSymptom,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.chat,
            title: 'Chat with Doctor',
            route: AppConstants.routeChat,
            isSelected: currentRoute == AppConstants.routeChat,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.local_hospital,
            title: 'Hospitals',
            route: AppConstants.routeHospital,
            isSelected: currentRoute == AppConstants.routeHospital,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.local_pharmacy,
            title: 'Pharmacies',
            route: AppConstants.routePharmacy,
            isSelected: currentRoute == AppConstants.routePharmacy,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.alarm,
            title: 'Reminders',
            route: AppConstants.routeReminder,
            isSelected: currentRoute == AppConstants.routeReminder,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.timeline,
            title: 'Medical Timeline',
            route: AppConstants.routeTimeline,
            isSelected: currentRoute == AppConstants.routeTimeline,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.emergency,
            title: 'SOS Emergency',
            route: AppConstants.routeSos,
            isSelected: currentRoute == AppConstants.routeSos,
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.person,
            title: 'Profile',
            route: AppConstants.routeProfile,
            isSelected: currentRoute == AppConstants.routeProfile,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? route,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet || isDesktop ? 24.0 : 16.0,
        vertical: isTablet || isDesktop ? 4.0 : 0.0,
      ),
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
        size: isTablet || isDesktop ? 28.0 : 24.0,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
          fontSize: isTablet || isDesktop ? 16.0 : 14.0,
        ),
      ),
      selected: isSelected,
      onTap: onTap ?? () {
        Navigator.pop(context); // Close drawer
        if (route != null && route != ModalRoute.of(context)?.settings.name) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
