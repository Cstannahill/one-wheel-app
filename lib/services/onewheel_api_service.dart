import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/ride.dart';
import '../models/ride_insights.dart';
import '../services/user_identification_service.dart';

/// Service for communicating with the OneWheel API server
class OneWheelApiService {
  static const String _baseUrl = 'http://192.168.0.112:80';
  static const String _demoToken = 'ow_demo_12345678901234567890123456789012';
  
  /// Upload ride data to the server
  static Future<bool> uploadRide(Ride ride) async {
    try {
      print('🚀 Uploading ride to OneWheel API...');
      
      // Get device ID for user identification
      final deviceId = await UserIdentificationService.instance.getDeviceId();
      
      // Prepare ride data according to API specification
      final rideData = {
        'id': ride.id,
        'startTime': ride.startTime.toIso8601String(),
        'endTime': ride.endTime?.toIso8601String(),
        'distance': ride.distance,
        'maxSpeed': ride.maxSpeed,
        'avgSpeed': ride.avgSpeed,
        'duration': ride.duration,
        'route': ride.route.map((point) => {
          'lat': point.latitude,
          'lng': point.longitude,
          'timestamp': ride.startTime.toIso8601String(), // Use start time as default
        }).toList(),
        'startBattery': ride.startBattery?.toInt() ?? 100,
        'endBattery': ride.endBattery?.toInt() ?? 80,
        'notes': ride.notes ?? '',
        'metadata': {
          'rideMode': 'Classic',
          'firmwareVersion': '4149',
          'boardModel': 'OneWheel',
          'deviceId': deviceId,
          'appVersion': '1.0.0',
          'uploadTime': DateTime.now().toIso8601String(),
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/rides'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_demoToken',
          'User-Agent': 'OneWheelApp/1.0.0',
        },
        body: json.encode(rideData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('✅ Ride uploaded successfully: ${responseData['rideId']}');
        return true;
      } else {
        print('❌ Server error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Upload failed: $e');
      return false;
    }
  }

  /// Get list of rides from server
  static Future<List<Ride>?> getRides({int page = 1, int pageSize = 20}) async {
    try {
      print('📥 Fetching rides from OneWheel API...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rides?page=$page&pageSize=$pageSize'),
        headers: {
          'Authorization': 'Bearer $_demoToken',
          'User-Agent': 'OneWheelApp/1.0.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final ridesData = responseData['rides'] as List;
        
        print('✅ Fetched ${ridesData.length} rides from server');
        
        // Convert simplified server response to full Ride objects
        return ridesData.map((rideJson) => _parseServerRide(rideJson)).toList();
      } else {
        print('❌ Server error fetching rides: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Failed to fetch rides: $e');
      return null;
    }
  }

  /// Get specific ride details from server
  static Future<Ride?> getRide(String rideId) async {
    try {
      print('📥 Fetching ride details for: $rideId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rides/$rideId'),
        headers: {
          'Authorization': 'Bearer $_demoToken',
          'User-Agent': 'OneWheelApp/1.0.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final rideData = json.decode(response.body);
        print('✅ Fetched ride details for: $rideId');
        return _parseFullServerRide(rideData);
      } else if (response.statusCode == 404) {
        print('❌ Ride not found: $rideId');
        return null;
      } else {
        print('❌ Server error fetching ride: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Failed to fetch ride: $e');
      return null;
    }
  }

  /// Check API health
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final healthData = json.decode(response.body);
        print('✅ API Health Check: ${healthData['status']}');
        return healthData['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  /// Parse simplified server ride response to Ride object
  static Ride _parseServerRide(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      deviceId: json['deviceId'], // Will be null for server rides, that's OK
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      distance: (json['distance'] ?? 0.0).toDouble(),
      maxSpeed: (json['maxSpeed'] ?? 0.0).toDouble(),
      avgSpeed: (json['avgSpeed'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? 0,
      route: [], // Simplified view doesn't include route
      startBattery: null, // Not included in simplified view
      endBattery: null, // Not included in simplified view
      notes: null, // Not included in simplified view
    );
  }

  /// Parse full server ride response to Ride object
  static Ride _parseFullServerRide(Map<String, dynamic> json) {
    // Parse route data
    final routeData = json['route'] as List? ?? [];
    final route = routeData.map((point) {
      return LatLng(
        (point['lat'] ?? 0.0).toDouble(),
        (point['lng'] ?? 0.0).toDouble(),
      );
    }).toList();

    return Ride(
      id: json['id'],
      deviceId: json['metadata']?['deviceId'], // Extract from metadata
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      distance: (json['distance'] ?? 0.0).toDouble(),
      maxSpeed: (json['maxSpeed'] ?? 0.0).toDouble(),
      avgSpeed: (json['avgSpeed'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? 0,
      route: route,
      startBattery: json['startBattery']?.toDouble(),
      endBattery: json['endBattery']?.toDouble(),
      notes: json['notes'],
    );
  }

  /// Generate local insights when server analysis is unavailable
  static RideInsights generateLocalInsights(Ride ride) {
    // Calculate basic metrics
    final efficiency = _calculateEfficiency(ride);
    final speedScore = _calculateSpeedScore(ride);
    final routeScore = _calculateRouteScore(ride);
    final overallScore = (efficiency + speedScore + routeScore) / 3;

    return RideInsights(
      rideId: ride.id,
      overallScore: overallScore,
      speedEfficiency: speedScore,
      energyEfficiency: efficiency,
      routeQuality: routeScore,
      rideStyle: _determineRideStyle(ride),
      insights: _generateInsightsList(ride, overallScore),
      suggestions: _generateSuggestions(ride),
      comparisons: _generateComparisons(ride),
      generatedAt: DateTime.now(),
      analysisType: 'local',
      aiMetrics: {
        'analysisType': 'local',
        'confidence': 0.75,
        'dataQuality': 'good',
      },
      moodAnalysis: _generateMoodAnalysis(ride),
      safetyTips: _generateSafetyTips(ride),
      skillProgression: _generateSkillProgression(ride),
    );
  }

  // Helper methods for local analysis
  static double _calculateEfficiency(Ride ride) {
    if (ride.startBattery == null || ride.endBattery == null) return 75.0;
    
    final batteryUsed = ride.startBattery! - ride.endBattery!;
    final efficiency = (ride.distance / batteryUsed) * 10; // miles per % battery
    return (efficiency * 10).clamp(0.0, 100.0);
  }

  static double _calculateSpeedScore(Ride ride) {
    final avgSpeedRatio = ride.avgSpeed / (ride.maxSpeed == 0 ? 1 : ride.maxSpeed);
    return (avgSpeedRatio * 100).clamp(0.0, 100.0);
  }

  static double _calculateRouteScore(Ride ride) {
    if (ride.route.isEmpty) return 70.0;
    
    final routeVariation = ride.route.length > 10 ? 85.0 : 60.0;
    return routeVariation;
  }

  static String _determineRideStyle(Ride ride) {
    if (ride.maxSpeed > 15.0) return 'Aggressive';
    if (ride.avgSpeed > 10.0) return 'Balanced';
    return 'Casual';
  }

  static List<String> _generateInsightsList(Ride ride, double score) {
    final insights = <String>[];
    
    if (score > 85) {
      insights.add('Excellent ride performance! You maintained great efficiency.');
    } else if (score > 70) {
      insights.add('Good ride with room for improvement in efficiency.');
    } else {
      insights.add('Consider smoother acceleration and braking for better efficiency.');
    }
    
    if (ride.distance > 5.0) {
      insights.add('Great distance covered! Building endurance.');
    }
    
    return insights;
  }

  static List<String> _generateSuggestions(Ride ride) {
    final suggestions = <String>[];
    
    if (ride.maxSpeed > 18.0) {
      suggestions.add('Consider maintaining speeds under 18 mph for safety.');
    }
    
    if (ride.distance < 2.0) {
      suggestions.add('Try extending your rides to build endurance.');
    }
    
    suggestions.add('Remember to wear protective gear on every ride.');
    
    return suggestions;
  }

  static List<String> _generateComparisons(Ride ride) {
    final comparisons = <String>[];
    
    if (ride.distance > 3.0) {
      comparisons.add('Distance above average rider');
    } else {
      comparisons.add('Distance below average rider');
    }
    
    if (ride.avgSpeed > 12.0) {
      comparisons.add('Speed above community average');
    } else {
      comparisons.add('Moderate pace rider');
    }
    
    if (ride.duration > 1800) {
      comparisons.add('Long duration ride');
    } else {
      comparisons.add('Quick session');
    }
    
    return comparisons;
  }

  static String _generateMoodAnalysis(Ride ride) {
    if (ride.maxSpeed > 16.0) {
      return 'Adventurous and confident - you pushed your limits today!';
    } else if (ride.distance > 4.0) {
      return 'Steady and determined - focused on endurance and exploration.';
    } else {
      return 'Relaxed and mindful - enjoying the journey at your own pace.';
    }
  }

  static List<String> _generateSafetyTips(Ride ride) {
    final tips = <String>[];
    
    if (ride.maxSpeed > 15.0) {
      tips.add('At higher speeds, lean forward slightly and keep knees bent.');
    }
    
    tips.add('Always check tire pressure before riding.');
    tips.add('Stay visible with lights in low-light conditions.');
    
    return tips;
  }

  static Map<String, double> _generateSkillProgression(Ride ride) {
    return {
      'balance': 75.0 + (ride.distance * 2), // Simple progression
      'efficiency': _calculateEfficiency(ride),
      'speed_control': ride.maxSpeed > 15.0 ? 85.0 : 70.0,
      'endurance': ride.duration > 1800 ? 80.0 : 65.0,
    };
  }
}
