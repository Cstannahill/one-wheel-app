import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/ride.dart';
import '../models/onewheel_stats.dart';
import '../models/ride_insights.dart';
import '../services/ride_analytics_service.dart';
import '../utils/unit_converter.dart';
import 'dart:io' show Platform;

class RideProvider with ChangeNotifier {
  List<Ride> _rides = [];
  Ride? _currentRide;
  bool _isRiding = false;
  List<LatLng> _currentRoute = [];
  OneWheelStats? _currentStats;
  
  // Real GPS tracking
  StreamSubscription<Position>? _locationStream;
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  
  // Analytics and insights
  Map<String, RideInsights> _rideInsights = {};
  bool _analyticsEnabled = true;

  List<Ride> get rides => _rides;
  Ride? get currentRide => _currentRide;
  bool get isRiding => _isRiding;
  List<LatLng> get currentRoute => _currentRoute;
  OneWheelStats? get currentStats => _currentStats;
  Map<String, RideInsights> get rideInsights => _rideInsights;
  bool get analyticsEnabled => _analyticsEnabled;

  // Total statistics
  double get totalDistance => _rides.fold(0, (sum, ride) => sum + ride.distance);
  int get totalRides => _rides.length;
  double get totalTime => _rides.fold(0, (sum, ride) => sum + ride.duration) / 3600; // in hours
  double get averageSpeed => totalDistance > 0 ? totalDistance / totalTime : 0;

  void startRide() async {
    if (_isRiding) return;

    try {
      LatLng startLocation;
      
      // Try to get actual location for real tracking
      if (!Platform.isLinux && !Platform.isWindows) {
        // Mobile platforms - try real GPS
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          startLocation = LatLng(position.latitude, position.longitude);
          _lastPosition = position;
          _lastPositionTime = DateTime.now();
          
          // Start real GPS tracking
          _startLocationTracking();
          
          print('✅ Real GPS tracking started at: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          print('Failed to get location, using default: $e');
          startLocation = const LatLng(37.7749, -122.4194);
        }
      } else {
        // Desktop development - use demo location but still track "movement"
        startLocation = const LatLng(37.7749, -122.4194);
        print('🖥️ Desktop mode: Using San Francisco demo location');
        _startDemoTracking(); // Simulate movement for testing
      }
      
      _currentRoute = [startLocation];
      _currentRide = Ride(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        distance: 0,
        maxSpeed: 0,
        avgSpeed: 0,
        duration: 0,
        route: _currentRoute,
        startBattery: _currentStats?.battery ?? 100,
      );
      
      // Update current stats with initial values
      _currentStats = OneWheelStats(
        speed: 0.0,
        battery: _currentStats?.battery ?? 100,
        temperature: _currentStats?.temperature ?? 72.0,
        voltage: 58.8, // Typical OneWheel voltage
        current: 0.0,
        rpm: 0.0,
        pitch: 0.0,
        roll: 0.0,
        yaw: 0.0,
        isConnected: false, // No actual board connection yet
        lastUpdated: DateTime.now(),
      );
      
      _isRiding = true;
      notifyListeners();
      
      print('🛹 Ride started! Real GPS tracking: ${!Platform.isLinux && !Platform.isWindows}');
    } catch (e) {
      print('Error starting ride: $e');
    }
  }

  void addRoutePoint(LatLng point) {
    if (_isRiding && _currentRide != null) {
      _currentRoute.add(point);
      
      // Calculate distance in miles
      double newDistance = _calculateTotalDistance(_currentRoute);
      
      // Calculate duration
      int duration = DateTime.now().difference(_currentRide!.startTime).inSeconds;
      
      // Calculate average speed in mph
      double avgSpeed = duration > 0 ? (newDistance / (duration / 3600.0)) : 0; // miles/hour
      
      _currentRide = _currentRide!.copyWith(
        route: List.from(_currentRoute),
        distance: newDistance,
        avgSpeed: avgSpeed,
        duration: duration,
      );
      
      notifyListeners();
    }
  }

  void updateCurrentSpeed(double speedKmh) {
    if (_isRiding && _currentRide != null) {
      double speedMph = UnitConverter.kmhToMph(speedKmh);
      _currentRide = _currentRide!.copyWith(
        maxSpeed: speedMph > _currentRide!.maxSpeed ? speedMph : _currentRide!.maxSpeed,
      );
      notifyListeners();
    }
  }

  void endRide() async {
    if (_isRiding && _currentRide != null) {
      // Stop GPS tracking
      _stopLocationTracking();
      
      final completedRide = _currentRide!.copyWith(
        endTime: DateTime.now(),
        endBattery: _currentStats?.battery ?? 0,
      );
      
      _rides.add(completedRide);
      _currentRide = null;
      _currentRoute = [];
      _isRiding = false;
      _lastPosition = null;
      _lastPositionTime = null;
      
      print('🏁 Ride ended! Distance: ${completedRide.distance.toStringAsFixed(2)} miles, Duration: ${completedRide.duration}s');
      notifyListeners();
      
      // Trigger automatic analytics if enabled
      if (_analyticsEnabled) {
        _analyzeRideAutomatically(completedRide);
      }
    }
  }

  /// Automatically analyze ride and upload to server
  Future<void> _analyzeRideAutomatically(Ride ride) async {
    try {
      print('🧠 Starting automatic ride analysis...');
      
      // Show loading state (you could add a loading indicator in UI)
      notifyListeners();
      
      // Upload and analyze ride
      final insights = await RideAnalyticsService.uploadAndAnalyzeRide(ride);
      
      if (insights != null) {
        _rideInsights[ride.id] = insights;
        print('✅ Ride analysis completed for ${ride.id}');
        print('📊 Overall Score: ${insights.overallScore.toStringAsFixed(1)}/100');
        print('🎯 Ride Style: ${insights.rideStyle}');
        print('💡 ${insights.insights.length} insights generated');
        
        notifyListeners();
        
        // You could trigger a notification or UI update here
        _showAnalysisCompleteNotification(insights);
      }
    } catch (e) {
      print('❌ Automatic ride analysis failed: $e');
    }
  }

  /// Show notification when analysis is complete
  void _showAnalysisCompleteNotification(RideInsights insights) {
    // This would trigger a snackbar or notification in the UI
    // For now, just print a summary
    print('🎉 Analysis Complete!');
    print('   ${insights.summary}');
    print('   ${insights.insights.isNotEmpty ? insights.insights.first : "No specific insights"}');
  }

  /// Get insights for a specific ride
  RideInsights? getInsightsForRide(String rideId) {
    return _rideInsights[rideId];
  }

  /// Toggle analytics on/off
  void setAnalyticsEnabled(bool enabled) {
    _analyticsEnabled = enabled;
    notifyListeners();
  }

  /// Manually trigger analysis for a specific ride
  Future<RideInsights?> analyzeRide(String rideId) async {
    final ride = _rides.firstWhere((r) => r.id == rideId);
    final insights = await RideAnalyticsService.uploadAndAnalyzeRide(ride);
    if (insights != null) {
      _rideInsights[rideId] = insights;
      notifyListeners();
    }
    return insights;
  }

  // Real GPS tracking for mobile
  void _startLocationTracking() {
    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Update every 1 meter
      ),
    ).listen(_onLocationUpdate);
  }
  
  void _stopLocationTracking() {
    _locationStream?.cancel();
    _locationStream = null;
  }
  
  void _onLocationUpdate(Position position) {
    if (!_isRiding || _currentRide == null) return;
    
    final newPoint = LatLng(position.latitude, position.longitude);
    final now = DateTime.now();
    
    // Calculate real-time speed from GPS
    double currentSpeed = 0.0;
    if (_lastPosition != null && _lastPositionTime != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      final timeDiff = now.difference(_lastPositionTime!).inMilliseconds / 1000.0;
      if (timeDiff > 0) {
        currentSpeed = (distance / timeDiff) * 3.6; // m/s to km/h
      }
    }
    
    // Update current stats with GPS speed
    _currentStats = OneWheelStats(
      speed: currentSpeed,
      battery: _currentStats?.battery ?? 100,
      temperature: _currentStats?.temperature ?? 72.0,
      voltage: 58.8,
      current: 0.0,
      rpm: 0.0,
      pitch: 0.0,
      roll: 0.0,
      yaw: 0.0,
      isConnected: false,
      lastUpdated: DateTime.now(),
    );
    
    // Add point to route and update ride stats
    addRoutePoint(newPoint);
    updateCurrentSpeed(currentSpeed);
    
    _lastPosition = position;
    _lastPositionTime = now;
    
    print('📍 GPS Update: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} - Speed: ${UnitConverter.kmhToMph(currentSpeed).toStringAsFixed(1)} mph');
  }
  
  // Demo tracking for desktop (simulates movement for testing)
  Timer? _demoTimer;
  int _demoStep = 0;
  
  void _startDemoTracking() {
    final startLat = 37.7749;
    final startLng = -122.4194;
    
    _demoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isRiding) {
        timer.cancel();
        return;
      }
      
      // Simulate movement in a small area around San Francisco
      _demoStep++;
      final lat = startLat + (_demoStep * 0.0001 * ((_demoStep % 4) - 2));
      final lng = startLng + (_demoStep * 0.0001 * ((_demoStep % 3) - 1));
      
      final demoPoint = LatLng(lat, lng);
      
      // Simulate speed between 5-15 mph
      final demoSpeed = 8.0 + (_demoStep % 10); // km/h
      
      _currentStats = OneWheelStats(
        speed: demoSpeed,
        battery: (_currentStats?.battery ?? 100) - 0.1,
        temperature: 72.0 + (_demoStep % 5),
        voltage: 58.8,
        current: 0.0,
        rpm: 0.0,
        pitch: 0.0,
        roll: 0.0,
        yaw: 0.0,
        isConnected: false,
        lastUpdated: DateTime.now(),
      );
      
      addRoutePoint(demoPoint);
      updateCurrentSpeed(demoSpeed);
      
      print('🎮 Demo Update: Step $_demoStep - Speed: ${UnitConverter.kmhToMph(demoSpeed).toStringAsFixed(1)} mph');
    });
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _demoTimer?.cancel();
    super.dispose();
  }

  void updateStats(OneWheelStats stats) {
    _currentStats = stats;
    
    // If riding, update max speed (convert km/h to mph)
    if (_isRiding) {
      updateCurrentSpeed(stats.speed);
    }
    
    notifyListeners();
  }

  void deleteRide(String rideId) {
    _rides.removeWhere((ride) => ride.id == rideId);
    notifyListeners();
  }

  double _calculateTotalDistance(List<LatLng> route) {
    if (route.length < 2) return 0;
    
    double totalDistance = 0;
    for (int i = 1; i < route.length; i++) {
      totalDistance += Geolocator.distanceBetween(
        route[i - 1].latitude,
        route[i - 1].longitude,
        route[i].latitude,
        route[i].longitude,
      );
    }
    return UnitConverter.kmToMiles(totalDistance / 1000); // Convert meters to km, then to miles
  }

  // Generate dummy rides for testing
  void generateDummyRides() {
    final now = DateTime.now();
    final dummyRides = [
      Ride(
        id: '1',
        startTime: now.subtract(Duration(days: 2)),
        endTime: now.subtract(Duration(days: 2, hours: -1)),
        distance: 9.6, // miles
        maxSpeed: 17.6, // mph
        avgSpeed: 11.6, // mph
        duration: 2970, // 49.5 minutes
        route: [
          LatLng(37.7749, -122.4194),
          LatLng(37.7849, -122.4094),
          LatLng(37.7949, -122.3994),
        ],
        startBattery: 100,
        endBattery: 45,
        notes: "Great ride through Golden Gate Park",
      ),
      Ride(
        id: '2',
        startTime: now.subtract(Duration(days: 1)),
        endTime: now.subtract(Duration(days: 1, hours: -1, minutes: -30)),
        distance: 13.7, // miles
        maxSpeed: 19.4, // mph
        avgSpeed: 12.7, // mph
        duration: 4500, // 75 minutes
        route: [
          LatLng(37.7649, -122.4094),
          LatLng(37.7749, -122.3994),
          LatLng(37.7849, -122.3894),
        ],
        startBattery: 95,
        endBattery: 12,
        notes: "Beach ride - amazing sunset",
      ),
      Ride(
        id: '3',
        startTime: now.subtract(Duration(hours: 3)),
        endTime: now.subtract(Duration(hours: 2, minutes: 15)),
        distance: 5.4, // miles
        maxSpeed: 15.6, // mph
        avgSpeed: 10.1, // mph
        duration: 1950, // 32.5 minutes
        route: [
          LatLng(37.7549, -122.4194),
          LatLng(37.7649, -122.4094),
          LatLng(37.7749, -122.3994),
        ],
        startBattery: 88,
        endBattery: 62,
        notes: "Quick ride to the coffee shop",
      ),
    ];
    
    _rides.addAll(dummyRides);
    notifyListeners();
  }
}
