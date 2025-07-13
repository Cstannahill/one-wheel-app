import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/user_identification_service.dart';

/// Provider for managing user profile and authentication state
class UserProvider with ChangeNotifier {
  static const String _userProfileKey = 'user_profile';
  
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;
  
  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _userProfile != null;
  String get deviceId => _userProfile?.deviceId ?? '';
  
  /// Initialize user profile on app start
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Get device UUID
      final deviceId = await UserIdentificationService.instance.getDeviceId();
      
      // Try to load existing profile
      await _loadUserProfile(deviceId);
      
      print('✅ User initialized with device ID: $deviceId');
      
    } catch (e) {
      _error = 'Failed to initialize user: $e';
      print('❌ User initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load user profile from local storage
  Future<void> _loadUserProfile(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      
      if (profileJson != null) {
        final profileData = json.decode(profileJson) as Map<String, dynamic>;
        _userProfile = UserProfile.fromJson(profileData);
        print('📱 Loaded existing user profile for: ${_userProfile!.displayName}');
      } else {
        // Create new profile with device ID
        _userProfile = UserProfile.create(deviceId: deviceId);
        await _saveUserProfile();
        print('🆕 Created new user profile with device ID: $deviceId');
      }
      
    } catch (e) {
      print('⚠️ Error loading user profile: $e');
      // Create fallback profile
      _userProfile = UserProfile.create(deviceId: deviceId);
      await _saveUserProfile();
    }
  }
  
  /// Save user profile to local storage
  Future<void> _saveUserProfile() async {
    if (_userProfile == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = json.encode(_userProfile!.toJson());
      await prefs.setString(_userProfileKey, profileJson);
      print('💾 User profile saved');
    } catch (e) {
      print('❌ Error saving user profile: $e');
      _error = 'Failed to save profile: $e';
      notifyListeners();
    }
  }
  
  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? preferences,
  }) async {
    if (_userProfile == null) return;
    
    try {
      _userProfile = _userProfile!.copyWith(
        name: name,
        email: email,
        phone: phone,
        preferences: preferences,
      );
      
      await _saveUserProfile();
      notifyListeners();
      
      print('✏️ User profile updated: ${_userProfile!.displayName}');
      
    } catch (e) {
      _error = 'Failed to update profile: $e';
      print('❌ Error updating profile: $e');
      notifyListeners();
    }
  }
  
  /// Clear user data (for testing/reset)
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      await UserIdentificationService.instance.clearDeviceId();
      
      _userProfile = null;
      _error = null;
      
      notifyListeners();
      
      // Reinitialize with new device ID
      await initialize();
      
      print('🗑️ User data cleared and reinitialized');
      
    } catch (e) {
      _error = 'Failed to clear user data: $e';
      print('❌ Error clearing user data: $e');
      notifyListeners();
    }
  }
  
  /// Get user preferences
  T? getPreference<T>(String key, {T? defaultValue}) {
    return _userProfile?.preferences[key] as T? ?? defaultValue;
  }
  
  /// Set user preference
  Future<void> setPreference<T>(String key, T value) async {
    if (_userProfile == null) return;
    
    final newPreferences = Map<String, dynamic>.from(_userProfile!.preferences);
    newPreferences[key] = value;
    
    await updateProfile(preferences: newPreferences);
  }
  
  /// Check if user can receive notifications
  bool get canReceiveNotifications => _userProfile?.canReceiveNotifications ?? false;
  
  /// Check if user has complete profile
  bool get hasCompleteProfile => _userProfile?.hasCompleteProfile ?? false;
  
  /// Get display information for UI
  Map<String, dynamic> get displayInfo {
    if (_userProfile == null) {
      return {
        'displayName': 'OneWheel Rider',
        'initials': 'OR',
        'hasProfile': false,
        'canNotify': false,
      };
    }
    
    return {
      'displayName': _userProfile!.displayName,
      'initials': _userProfile!.initials,
      'hasProfile': _userProfile!.hasCompleteProfile,
      'canNotify': _userProfile!.canReceiveNotifications,
      'email': _userProfile!.email,
      'phone': _userProfile!.phone,
      'deviceId': _userProfile!.deviceId,
    };
  }
  
  /// Generate user data for server sync (anonymous)
  Map<String, dynamic> toServerData() {
    if (_userProfile == null) return {};
    
    return {
      'deviceId': _userProfile!.deviceId,
      'hasName': _userProfile!.name != null,
      'hasEmail': _userProfile!.email != null,
      'hasPhone': _userProfile!.phone != null,
      'createdAt': _userProfile!.createdAt.toIso8601String(),
      'preferences': _userProfile!.preferences,
      // Note: We don't send actual name/email/phone to server for privacy
      // Server only needs to know device ID and what capabilities are available
    };
  }
}
