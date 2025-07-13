import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../providers/user_provider.dart';
import '../services/onewheel_ble_service.dart';
import 'onewheel_connection_screen.dart';
import 'user_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0E0E0),
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // OneWheel Connection Section
          _buildSection(
            context,
            'OneWheel Connection',
            [
              Consumer<OnewheelBleService>(
                builder: (context, bleService, child) {
                  return ListTile(
                    leading: Icon(
                      bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                      color: bleService.isConnected ? Colors.green : const Color(0xFF7C4DFF),
                    ),
                    title: Text(
                      bleService.isConnected 
                        ? 'Connected to ${bleService.connectedDevice?.platformName ?? "OneWheel"}' 
                        : 'Connect OneWheel',
                      style: const TextStyle(color: Color(0xFFE0E0E0)),
                    ),
                    subtitle: Text(
                      bleService.isConnected 
                        ? 'Receiving real-time data'
                        : 'Tap to scan and connect',
                      style: const TextStyle(color: Color(0xFF757575)),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: const Color(0xFF7C4DFF),
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnewheelConnectionScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // User Profile Section
          _buildSection(
            context,
            'User Profile',
            [
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final displayInfo = userProvider.displayInfo;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF00D4FF).withOpacity(0.2),
                      child: Text(
                        displayInfo['initials'],
                        style: const TextStyle(
                          color: Color(0xFF00D4FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      displayInfo['displayName'],
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      displayInfo['hasProfile'] 
                        ? 'Profile complete' 
                        : 'Tap to add profile information',
                      style: TextStyle(
                        color: displayInfo['hasProfile'] 
                          ? const Color(0xFF00FF88) 
                          : const Color(0xFFB0B0B0),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF7C4DFF),
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfileScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // App Info Section
          _buildSection(
            context,
            'App Information',
            [
              _buildInfoTile(
                'Version',
                '1.0.0',
                Icons.info_outline,
              ),
              _buildInfoTile(
                'Developer',
                'OneWheel Tracker Team',
                Icons.code,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Data Management Section
          _buildSection(
            context,
            'Data Management',
            [
              Consumer<RideProvider>(
                builder: (context, rideProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Export Rides'),
                    subtitle: Text('Export ${rideProvider.rides.length} rides'),
                    onTap: () {
                      _showComingSoonDialog(context, 'Ride export functionality coming soon!');
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('Backup to Cloud'),
                subtitle: const Text('Sync your rides to the cloud'),
                onTap: () {
                  _showComingSoonDialog(context, 'Cloud backup coming soon!');
                },
              ),
              Consumer<RideProvider>(
                builder: (context, rideProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                    subtitle: Text('Delete ${rideProvider.rides.length} rides permanently'),
                    onTap: () {
                      _showClearDataDialog(context, rideProvider);
                    },
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Preferences Section
          _buildSection(
            context,
            'Preferences',
            [
              ListTile(
                leading: const Icon(
                  Icons.palette,
                  color: Color(0xFF7C4DFF),
                ),
                title: const Text(
                  'Theme',
                  style: TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Dark Mode (Active)',
                  style: TextStyle(color: Color(0xFF00D4FF)),
                ),
                trailing: const Icon(Icons.check, color: Color(0xFF00FF88)),
                onTap: () {
                  _showThemeDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.straighten,
                  color: Color(0xFF00FF88),
                ),
                title: const Text(
                  'Units',
                  style: TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Imperial (mph, miles, °F)',
                  style: TextStyle(color: Color(0xFFB0B0B0)),
                ),
                onTap: () {
                  _showComingSoonDialog(context, 'Unit preferences coming soon!');
                },
              ),
              Consumer<RideProvider>(
                builder: (context, rideProvider, child) {
                  return ListTile(
                    leading: const Icon(
                      Icons.analytics,
                      color: Color(0xFF00D4FF),
                    ),
                    title: const Text(
                      'Ride Analytics',
                      style: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      rideProvider.analyticsEnabled 
                        ? 'Auto-analyze rides with AI insights' 
                        : 'Manual analysis only',
                      style: TextStyle(
                        color: rideProvider.analyticsEnabled 
                          ? const Color(0xFF00FF88) 
                          : const Color(0xFFB0B0B0),
                      ),
                    ),
                    trailing: Switch(
                      value: rideProvider.analyticsEnabled,
                      onChanged: (value) {
                        rideProvider.setAnalyticsEnabled(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value 
                                ? '🧠 AI analytics enabled - rides will be auto-analyzed' 
                                : '📊 AI analytics disabled - manual analysis only',
                            ),
                            backgroundColor: const Color(0xFF1A1A1A),
                          ),
                        );
                      },
                      activeColor: const Color(0xFF00D4FF),
                      activeTrackColor: const Color(0xFF00D4FF).withOpacity(0.3),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                subtitle: const Text('Ride reminders and alerts'),
                onTap: () {
                  _showComingSoonDialog(context, 'Notification settings coming soon!');
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSection(
            context,
            'About',
            [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  _showComingSoonDialog(context, 'Help documentation coming soon!');
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                onTap: () {
                  _showComingSoonDialog(context, 'Privacy policy coming soon!');
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                onTap: () {
                  _showComingSoonDialog(context, 'Terms of service coming soon!');
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Debug Section (for development)
          _buildSection(
            context,
            'Debug (Development Only)',
            [
              Consumer<RideProvider>(
                builder: (context, rideProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Generate Dummy Rides'),
                    subtitle: const Text('Add sample ride data for testing'),
                    onTap: () {
                      rideProvider.generateDummyRides();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dummy rides generated!')),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00D4FF),
              shadows: [
                Shadow(
                  color: Color(0xFF00D4FF),
                  blurRadius: 4,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF2A2A2A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            color: Colors.transparent,
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF00D4FF),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 14,
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Coming Soon',
          style: TextStyle(
            color: Color(0xFF00D4FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFE0E0E0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00D4FF),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, RideProvider rideProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Clear All Data',
          style: TextStyle(
            color: Color(0xFFFF3366),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all ${rideProvider.rides.length} rides? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFFE0E0E0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB0B0B0),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear all rides
              for (final ride in List.from(rideProvider.rides)) {
                rideProvider.deleteRide(ride.id);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All data cleared'),
                  backgroundColor: const Color(0xFF1A1A1A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3366),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Choose Theme',
          style: TextStyle(
            color: Color(0xFF00D4FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode, color: Color(0xFFFFD700)),
              title: const Text(
                'Light',
                style: TextStyle(color: Color(0xFFE0E0E0)),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog(context, 'Theme switching coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode, color: Color(0xFF00D4FF)),
              title: const Text(
                'Dark',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.check, color: Color(0xFF00FF88)),
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog(context, 'Already using dark theme!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_mode, color: Color(0xFF7C4DFF)),
              title: const Text(
                'System',
                style: TextStyle(color: Color(0xFFE0E0E0)),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog(context, 'Theme switching coming soon!');
              },
            ),
          ],
        ),
      ),
    );
  }
}
