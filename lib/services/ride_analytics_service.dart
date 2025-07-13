import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ride.dart';
import '../models/ride_insights.dart';
import '../services/onewheel_api_service.dart';

class RideAnalyticsService {
  /// Upload ride data to server and get AI analysis
  static Future<RideInsights?> uploadAndAnalyzeRide(Ride ride) async {
    try {
      print('🚀 Uploading ride data to OneWheel API...');
      
      // Upload to the real OneWheel API server
      final uploadSuccess = await OneWheelApiService.uploadRide(ride);
      
      if (uploadSuccess) {
        print('✅ Ride uploaded successfully to OneWheel API');
        // Generate local insights since server analysis isn't implemented yet
        return OneWheelApiService.generateLocalInsights(ride);
      } else {
        print('❌ Failed to upload ride data, generating local insights');
        return OneWheelApiService.generateLocalInsights(ride);
      }
      
    } catch (e) {
      print('❌ Error in ride analytics: $e');
      return OneWheelApiService.generateLocalInsights(ride); // Always provide some insights
    }
  }
}
