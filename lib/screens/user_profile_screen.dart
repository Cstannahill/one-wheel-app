import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/user_identification_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final userProvider = context.read<UserProvider>();
    final profile = userProvider.userProfile;
    
    if (profile != null) {
      _nameController.text = profile.name ?? '';
      _emailController.text = profile.email ?? '';
      _phoneController.text = profile.phone ?? '';
    }
    
    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0E0E0),
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _isLoading ? Colors.grey : const Color(0xFF00D4FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D4FF),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(userProvider),
                
                const SizedBox(height: 32),
                
                // Profile Form
                _buildProfileForm(),
                
                const SizedBox(height: 32),
                
                // Device Information
                _buildDeviceInfo(),
                
                const SizedBox(height: 32),
                
                // Privacy Information
                _buildPrivacyInfo(),
                
                const SizedBox(height: 32),
                
                // Actions
                _buildActions(userProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProvider userProvider) {
    final displayInfo = userProvider.displayInfo;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00D4FF),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                displayInfo['initials'],
                style: const TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Display Name
          Text(
            displayInfo['displayName'],
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Status indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusChip(
                'Profile',
                displayInfo['hasProfile'] ? 'Complete' : 'Incomplete',
                displayInfo['hasProfile'] ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildStatusChip(
                'Notifications',
                displayInfo['canNotify'] ? 'Enabled' : 'Disabled',
                displayInfo['canNotify'] ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF333333),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Optional: Add your information for enhanced features like notifications and data backup.',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Name Field
            _buildFormField(
              controller: _nameController,
              label: 'Display Name',
              hint: 'Enter your name (optional)',
              icon: Icons.person_outline,
              validator: null, // Name is optional
            ),
            
            const SizedBox(height: 16),
            
            // Email Field
            _buildFormField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'Enter email for notifications (optional)',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Phone Field
            _buildFormField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter phone for SMS notifications (optional)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  // Basic phone validation
                  if (!RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(value)) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Color(0xFFE0E0E0)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF757575)),
            prefixIcon: Icon(icon, color: const Color(0xFF757575)),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00D4FF)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF333333),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Information',
            style: TextStyle(
              color: Color(0xFF00D4FF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          FutureBuilder<Map<String, String>>(
            future: UserIdentificationService.instance.getDeviceInfo(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: snapshot.data!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (entry.key == 'Device ID')
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                color: Color(0xFF757575),
                                size: 16,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: entry.value));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Device ID copied to clipboard'),
                                    backgroundColor: Color(0xFF1A1A1A),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }
              
              return const CircularProgressIndicator(
                color: Color(0xFF00D4FF),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00FF88).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.security,
                color: Color(0xFF00FF88),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Privacy & Security',
                style: TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            '• Your device is identified by a unique UUID for privacy\n'
            '• Personal information (name, email, phone) is stored locally only\n'
            '• Server receives anonymous device ID for ride data association\n'
            '• You can clear all data anytime from settings\n'
            '• No tracking or analytics are performed on personal data',
            style: TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(UserProvider userProvider) {
    return Column(
      children: [
        // Clear Data Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _showClearDataDialog(userProvider),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Clear All User Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      
      await userProvider.updateProfile(
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully'),
            backgroundColor: Color(0xFF1A1A1A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showClearDataDialog(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Clear All User Data',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This will permanently delete your profile information and generate a new device ID. This action cannot be undone.\n\nYour ride data will not be affected.',
          style: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFB0B0B0)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isLoading = true;
              });
              
              await userProvider.clearUserData();
              
              // Reload form with new profile
              _loadCurrentProfile();
              
              setState(() {
                _isLoading = false;
                _hasChanges = false;
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ User data cleared and new device ID generated'),
                    backgroundColor: Color(0xFF1A1A1A),
                  ),
                );
              }
            },
            child: const Text(
              'Clear Data',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
