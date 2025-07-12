import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ride.dart';
import '../models/ride_insights.dart';

class RideAnalyticsService {
  static const String _baseUrl = 'https://api.onewheelapp.com'; // Replace with your actual API
  static const String _apiKey = 'your-api-key-here'; // Configure your API key
  
  /// Upload ride data to server and get AI analysis
  static Future<RideInsights?> uploadAndAnalyzeRide(Ride ride) async {
    try {
      print('🚀 Uploading ride data for AI analysis...');
      
      // Prepare ride data for upload
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
        }).toList(),
        'startBattery': ride.startBattery,
        'endBattery': ride.endBattery,
        'notes': ride.notes,
        'metadata': {
          'appVersion': '1.0.0',
          'deviceType': 'mobile',
          'uploadTime': DateTime.now().toIso8601String(),
        }
      };

      // Upload to server
      final uploadResponse = await _uploadRideData(rideData);
      if (!uploadResponse) {
        print('❌ Failed to upload ride data');
        return _generateLocalInsights(ride); // Fallback to local analysis
      }

      // Request AI analysis
      final insights = await _requestAIAnalysis(ride.id, rideData);
      if (insights != null) {
        print('✅ AI analysis completed successfully');
        return insights;
      }

      // Fallback to local analysis if AI service unavailable
      print('⚠️ AI service unavailable, generating local insights');
      return _generateLocalInsights(ride);
      
    } catch (e) {
      print('❌ Error in ride analytics: $e');
      return _generateLocalInsights(ride); // Always provide some insights
    }
  }

  /// Upload ride data to server
  static Future<bool> _uploadRideData(Map<String, dynamic> rideData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/rides'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'User-Agent': 'OneWheelApp/1.0.0',
        },
        body: json.encode(rideData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Ride data uploaded successfully');
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

  /// Request AI analysis from server
  static Future<RideInsights?> _requestAIAnalysis(String rideId, Map<String, dynamic> rideData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/analyze-ride'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'rideId': rideId,
          'analysisType': 'comprehensive',
          'includeComparisons': true,
          'includeSuggestions': true,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RideInsights.fromServerResponse(data);
      } else {
        print('❌ AI analysis failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ AI analysis error: $e');
      return null;
    }
  }

  /// Generate local insights when server/AI is unavailable
  static RideInsights _generateLocalInsights(Ride ride) {
    print('🔧 Generating local ride insights...');
    
    // Calculate basic metrics
    final speedEfficiency = _calculateSpeedEfficiency(ride);
    final routeQuality = _analyzeRouteQuality(ride);
    final energyEfficiency = _calculateEnergyEfficiency(ride);
    final rideStyle = _determineRideStyle(ride);
    
    // Generate insights
    final insights = <String>[];
    final suggestions = <String>[];
    
    // Speed analysis
    if (ride.maxSpeed > 15.0) {
      insights.add('🚀 High speed ride! Peak speed: ${ride.maxSpeed.toStringAsFixed(1)} mph');
      suggestions.add('Consider practicing speed control for safer rides');
    }
    
    if (ride.avgSpeed < 5.0) {
      insights.add('🐌 Leisurely pace ride - great for enjoying scenery');
    } else if (ride.avgSpeed > 12.0) {
      insights.add('⚡ Fast-paced ride - excellent speed consistency');
    }
    
    // Distance analysis
    if (ride.distance > 10.0) {
      insights.add('🏆 Long distance ride! Excellent endurance');
      suggestions.add('Great distance! Consider planning rest stops for longer rides');
    } else if (ride.distance < 1.0) {
      insights.add('🎯 Short practice session - perfect for skill building');
    }
    
    // Battery efficiency
    final batteryUsed = ride.startBattery - (ride.endBattery ?? 0);
    final efficiency = ride.distance / (batteryUsed > 0 ? batteryUsed : 1);
    if (efficiency > 0.15) {
      insights.add('🔋 Excellent battery efficiency!');
    } else if (efficiency < 0.08) {
      suggestions.add('Consider more efficient riding techniques to improve battery life');
    }
    
    // Route analysis
    if (ride.route.length > 20) {
      insights.add('🗺️ Complex route with good GPS tracking');
    }
    
    return RideInsights(
      rideId: ride.id,
      overallScore: _calculateOverallScore(ride),
      speedEfficiency: speedEfficiency,
      energyEfficiency: energyEfficiency,
      routeQuality: routeQuality,
      rideStyle: rideStyle,
      insights: insights,
      suggestions: suggestions,
      comparisons: _generateComparisons(ride),
      generatedAt: DateTime.now(),
      analysisType: 'local',
    );
  }

  static double _calculateSpeedEfficiency(Ride ride) {
    if (ride.maxSpeed == 0) return 0.0;
    return (ride.avgSpeed / ride.maxSpeed) * 100;
  }

  static double _analyzeRouteQuality(Ride ride) {
    // Simple route quality based on GPS point density
    final pointsPerMile = ride.route.length / (ride.distance > 0 ? ride.distance : 1);
    return (pointsPerMile / 100).clamp(0.0, 1.0) * 100;
  }

  static double _calculateEnergyEfficiency(Ride ride) {
    final batteryUsed = ride.startBattery - (ride.endBattery ?? 0);
    if (batteryUsed <= 0) return 100.0;
    return ((ride.distance / batteryUsed) * 10).clamp(0.0, 100.0);
  }

  static String _determineRideStyle(Ride ride) {
    if (ride.avgSpeed > 12.0) return 'Speed Demon';
    if (ride.distance > 10.0) return 'Endurance Rider';
    if (ride.maxSpeed > 18.0) return 'Adrenaline Seeker';
    if (ride.avgSpeed < 6.0) return 'Leisure Cruiser';
    return 'Balanced Rider';
  }

  static double _calculateOverallScore(Ride ride) {
    double score = 50.0; // Base score
    
    // Distance bonus
    score += (ride.distance * 2).clamp(0, 20);
    
    // Speed consistency bonus
    if (ride.maxSpeed > 0) {
      final consistency = (ride.avgSpeed / ride.maxSpeed) * 100;
      score += (consistency * 0.2).clamp(0, 20);
    }
    
    // Duration bonus
    final hours = ride.duration / 3600.0;
    score += (hours * 5).clamp(0, 10);
    
    return score.clamp(0.0, 100.0);
  }

  static List<String> _generateComparisons(Ride ride) {
    return [
      'This ride was ${ride.distance > 5 ? "longer" : "shorter"} than your average',
      'Speed was ${ride.avgSpeed > 8 ? "above" : "below"} your typical pace',
      'Battery efficiency was ${_calculateEnergyEfficiency(ride) > 50 ? "good" : "could be improved"}',
    ];
  }
}
