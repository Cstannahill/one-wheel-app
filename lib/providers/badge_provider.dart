import 'package:flutter/material.dart';
import '../models/badge.dart' as app_badge;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/user_identification_service.dart';

class BadgeProvider with ChangeNotifier {
  List<app_badge.Badge> _badges = [];
  bool _isLoading = false;

  List<app_badge.Badge> get badges => _badges;
  bool get isLoading => _isLoading;

  Future<void> loadBadges() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get device ID for user identification
      final deviceId = await UserIdentificationService.instance.getDeviceId();
      
      // Try to fetch badges from server first
      await fetchBadges(deviceId);
      
    } catch (e) {
      print('Error loading badges: $e');
      // If server fails, load local dummy badges
      await _loadLocalBadges();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadLocalBadges() async {
    print('📱 Loading local demo badges...');
    
    final deviceId = await UserIdentificationService.instance.getDeviceId();
    
    _badges = [
      app_badge.Badge(
        id: '1_$deviceId',
        type: 'first_ride',
        name: 'First Ride',
        description: 'Complete your very first ride',
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      app_badge.Badge(
        id: '2_$deviceId',
        type: 'distance_warrior',
        name: 'Distance Warrior',
        description: 'Ride 10 miles in total',
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      app_badge.Badge(
        id: '3_$deviceId',
        type: 'speed_demon',
        name: 'Speed Demon',
        description: 'Reach 20 mph',
        isEarned: false,
        earnedDate: null,
      ),
      app_badge.Badge(
        id: '4_$deviceId',
        type: 'explorer',
        name: 'Explorer',
        description: 'Visit 5 different locations',
        isEarned: false,
        earnedDate: null,
      ),
      app_badge.Badge(
        id: '5_$deviceId',
        type: 'endurance',
        name: 'Endurance Rider',
        description: 'Ride for 60 minutes straight',
        isEarned: false,
        earnedDate: null,
      ),
      app_badge.Badge(
        id: '6_$deviceId',
        type: 'consistency',
        name: 'Consistent Rider',
        description: 'Ride 7 days in a row',
        isEarned: false,
        earnedDate: null,
      ),
    ];
  }

  Future<void> fetchBadges(String deviceId) async {
    try {
      print('🏆 Attempting to fetch badges from OneWheel API for device: $deviceId');
      
      // Note: Badge endpoint doesn't exist yet in the API, so this will fall back to local
      const response = null; // Placeholder for when server supports badges
      
      if (response == null) {
        print('📱 Badge API not available, using local badges');
        await _loadLocalBadges();
        return;
      }
      
      // When server supports badges, parse response here
      // final List<dynamic> data = json.decode(response.body);
      // _badges = data.map((b) => app_badge.Badge.fromJson(b)).toList();
      
    } catch (e) {
      print('❌ Error fetching badges: $e');
      await _loadLocalBadges();
    }
  }
}
