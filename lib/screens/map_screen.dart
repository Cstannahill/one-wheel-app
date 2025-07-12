import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../providers/ride_provider.dart';
import '../utils/unit_converter.dart';
import '../widgets/adaptive_map.dart';
import 'ride_insights_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  dynamic _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location service not enabled - using default location');
        // Use default location if service disabled
        setState(() {
          _currentLocation = LatLng(37.7749, -122.4194); // San Francisco
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied - using default location');
          // Use default location if permission denied
          setState(() {
            _currentLocation = LatLng(37.7749, -122.4194); // San Francisco
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied - using default location');
        // Use default location if permission permanently denied
        setState(() {
          _currentLocation = LatLng(37.7749, -122.4194); // San Francisco
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      print('This is normal on Linux desktop - using San Francisco as default location');
      // Default to San Francisco if location fails
      setState(() {
        _currentLocation = LatLng(37.7749, -122.4194); // San Francisco
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ride Map',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0E0E0),
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer<RideProvider>(
            builder: (context, rideProvider, child) {
              return IconButton(
                icon: Icon(
                  rideProvider.isRiding ? Icons.stop : Icons.play_arrow,
                  color: rideProvider.isRiding 
                    ? const Color(0xFFFF3366) 
                    : const Color(0xFF00FF88),
                ),
                onPressed: () {
                  if (rideProvider.isRiding) {
                    rideProvider.endRide();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.analytics, color: Color(0xFF00D4FF)),
                            const SizedBox(width: 8),
                            const Text('Ride ended! Analyzing your performance...'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1A1A1A),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } else {
                    rideProvider.startRide();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ride started! GPS tracking enabled.'),
                        backgroundColor: Color(0xFF1A1A1A),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: _isLoadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF00D4FF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Getting your location...',
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'On Linux, location services may not be available.\nUsing San Francisco as default location.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFB0B0B0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Map
                AdaptiveMap(
                  initialCenter: _currentLocation!,
                  initialZoom: 15.0,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: true,
                ),
                
                // Ride Control Panel
                Consumer<RideProvider>(
                  builder: (context, rideProvider, child) {
                    return Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                              color: const Color(0xFF00D4FF).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                            const BoxShadow(
                              color: Colors.black54,
                              blurRadius: 12,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: rideProvider.isRiding
                                    ? const Color(0xFF00FF88).withOpacity(0.2)
                                    : const Color(0xFF7C4DFF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: rideProvider.isRiding
                                      ? const Color(0xFF00FF88)
                                      : const Color(0xFF7C4DFF),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                rideProvider.isRiding ? 'RIDING' : 'READY',
                                style: TextStyle(
                                  color: rideProvider.isRiding
                                      ? const Color(0xFF00FF88)
                                      : const Color(0xFF7C4DFF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildRideInfo(
                                  'Distance',
                                  UnitConverter.formatDistance(rideProvider.currentRide?.distance ?? 0.0),
                                  Icons.straighten,
                                  const Color(0xFF00FF88),
                                ),
                                _buildRideInfo(
                                  'Speed',
                                  '${UnitConverter.kmhToMph(rideProvider.currentStats?.speed ?? 0.0).toStringAsFixed(1)} mph',
                                  Icons.speed,
                                  const Color(0xFF00D4FF),
                                ),
                                _buildRideInfo(
                                  'Avg Speed',
                                  '${(rideProvider.currentRide?.avgSpeed ?? 0.0).toStringAsFixed(1)} mph',
                                  Icons.trending_up,
                                  const Color(0xFF7C4DFF),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Previous Rides Button
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: Consumer<RideProvider>(
                    builder: (context, rideProvider, child) {
                      if (rideProvider.rides.isEmpty) return const SizedBox();
                      
                      return FloatingActionButton(
                        onPressed: () => _showPreviousRidesDialog(context, rideProvider),
                        backgroundColor: const Color(0xFF1A1A1A),
                        child: const Icon(
                          Icons.history,
                          color: Color(0xFF00D4FF),
                        ),
                      );
                    },
                  ),
                ),

                // Location Button
                Positioned(
                  bottom: 30,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    backgroundColor: const Color(0xFF1A1A1A),
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF00FF88),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRideInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFB0B0B0),
          ),
        ),
      ],
    );
  }

  void _showPreviousRidesDialog(BuildContext context, RideProvider rideProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Previous Rides',
          style: TextStyle(
            color: Color(0xFF00D4FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: rideProvider.rides.length,
            itemBuilder: (context, index) {
              final ride = rideProvider.rides[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2A2A2A),
                      Color(0xFF1A1A1A),
                    ],
                  ),
                ),
                child: ListTile(
                  title: Text(
                    'Ride ${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${UnitConverter.formatDistance(ride.distance)} • ${UnitConverter.formatDuration(Duration(seconds: ride.duration))} • ${ride.avgSpeed.toStringAsFixed(1)} mph avg',
                        style: const TextStyle(color: Color(0xFFB0B0B0)),
                      ),
                      if (rideProvider.getInsightsForRide(ride.id) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.analytics,
                                size: 12,
                                color: Color(0xFF00D4FF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Analysis Available',
                                style: const TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rideProvider.getInsightsForRide(ride.id) != null)
                        IconButton(
                          icon: const Icon(
                            Icons.insights,
                            color: Color(0xFFFFB74D),
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RideInsightsScreen(rideId: ride.id),
                              ),
                            );
                          },
                        ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF00D4FF),
                        size: 16,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Show this ride on map (simplified for now)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Showing Ride ${index + 1} on map'),
                        backgroundColor: const Color(0xFF1A1A1A),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00D4FF),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
