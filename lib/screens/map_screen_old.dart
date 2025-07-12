import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../providers/ride_provider.dart';
import '../utils/unit_converter.dart';
import '../widgets/adaptive_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  dynamic _mapController; // Can be either MapLibre or FlutterMap controller
  LatLng _currentLocation = const LatLng(37.7749, -122.4194); // Default to San Francisco
  bool _locationPermissionGranted = false;
  List<LatLng> _currentRoutePoints = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // Skip permission checks on Linux/Windows for development
    if (Platform.isLinux || Platform.isWindows) {
      setState(() {
        _locationPermissionGranted = true;
      });
      return;
    }
    
    // For mobile platforms, try to get location
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        setState(() {
          _locationPermissionGranted = true;
        });
        _getCurrentLocation();
      }
    } catch (e) {
      print('Location permission error: $e');
      // Continue with default location
      setState(() {
        _locationPermissionGranted = true;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      // Note: Map controller animation will be handled differently for each map type
    } catch (e) {
      print('Error getting location: $e');
      // Use default location
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map & Tracking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0E0E0),
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFF00D4FF)),
            onPressed: _getCurrentLocation,
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            icon: const Icon(Icons.more_vert, color: Color(0xFF00D4FF)),
            color: const Color(0xFF1A1A1A),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'current_ride',
                child: Text(
                  'Show Current Ride',
                  style: TextStyle(color: Color(0xFFE0E0E0)),
                ),
              ),
              const PopupMenuItem(
                value: 'all_rides',
                child: Text(
                  'Show All Rides',
                  style: TextStyle(color: Color(0xFFE0E0E0)),
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text(
                  'Clear Map',
                  style: TextStyle(color: Color(0xFFE0E0E0)),
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Adaptive Map (MapLibre for mobile, Flutter Map for web/desktop)
          Consumer<RideProvider>(
            builder: (context, rideProvider, child) {
              // Prepare route points for the current route
              List<LatLng> routePoints = [];
              if (rideProvider.isRiding && rideProvider.currentRoute.isNotEmpty) {
                routePoints = rideProvider.currentRoute;
              }

              return AdaptiveMap(
                initialCenter: _currentLocation,
                initialZoom: 15,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: _locationPermissionGranted,
                routePoints: routePoints,
                onStyleLoaded: () {
                  _updateMapData(rideProvider);
                },
              );
            },
          ),

          // Ride Control Panel
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Consumer<RideProvider>(
              builder: (context, rideProvider, child) {
                return Container(
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
                        color: const Color(0xFF00D4FF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 0,
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (rideProvider.isRiding) ...[
                            // Current Ride Info
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3366),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF3366).withOpacity(0.6),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Recording',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDuration(rideProvider.currentRide?.duration ?? 0),
                                  style: const TextStyle(
                                    color: Color(0xFF00D4FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
                          ],
                          
                          // Control Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (rideProvider.isRiding) {
                                      _showEndRideDialog(rideProvider);
                                    } else {
                                      rideProvider.startRide();
                                    }
                                  },
                                  icon: Icon(
                                    rideProvider.isRiding ? Icons.stop : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    rideProvider.isRiding ? 'End Ride' : 'Start Ride',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: rideProvider.isRiding 
                                        ? const Color(0xFFFF3366)
                                        : const Color(0xFF00FF88),
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    shadowColor: rideProvider.isRiding 
                                        ? const Color(0xFFFF3366).withOpacity(0.5)
                                        : const Color(0xFF00FF88).withOpacity(0.5),
                                  ),
                                ),
                              ),
                              if (!rideProvider.isRiding) ...[
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _showRideSelectionDialog,
                                  icon: const Icon(
                                    Icons.route,
                                    color: Color(0xFF0A0A0A),
                                  ),
                                  label: const Text(
                                    'View Rides',
                                    style: TextStyle(
                                      color: Color(0xFF0A0A0A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00D4FF),
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    shadowColor: const Color(0xFF00D4FF).withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Location Permission Warning
          if (!_locationPermissionGranted)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.orange,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Location permission required for tracking',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: _initializeLocation,
                        child: const Text(
                          'Grant',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRideInfo(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon, 
            size: 20,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
              shadows: [
                Shadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _updateMapData(RideProvider rideProvider) {
    if (_mapController == null) return;
    
    // Clear existing annotations
    _mapController!.clearLines();
    _mapController!.clearSymbols();

    // Show current ride
    if (rideProvider.isRiding && rideProvider.currentRoute.isNotEmpty) {
      _mapController!.addLine(
        LineOptions(
          geometry: rideProvider.currentRoute,
          lineColor: "#00D4FF", // Electric blue
          lineWidth: 4.0,
          lineOpacity: 0.8,
        ),
      );

      // Add start marker
      if (rideProvider.currentRoute.isNotEmpty) {
        _mapController!.addSymbol(
          SymbolOptions(
            geometry: rideProvider.currentRoute.first,
            iconImage: "marker-15", // Built-in MapLibre icon
            iconColor: "#00FF88", // Green
            textField: "Start",
            textOffset: const Offset(0, 2),
            textColor: "#FFFFFF",
          ),
        );
      }
    }
  }

  void _onMenuSelected(String value) {
    final rideProvider = context.read<RideProvider>();
    
    switch (value) {
      case 'current_ride':
        if (rideProvider.isRiding && rideProvider.currentRoute.isNotEmpty) {
          _showRouteOnMap([rideProvider.currentRoute], ['Current Ride']);
        }
        break;
      case 'all_rides':
        final routes = rideProvider.rides.map((ride) => ride.route).toList();
        final names = rideProvider.rides.map((ride) => 'Ride ${ride.id}').toList();
        _showRouteOnMap(routes, names);
        break;
      case 'clear':
        setState(() {
          _lines.clear();
          _symbols.clear();
        });
        break;
    }
  }

  void _showRouteOnMap(List<List<LatLng>> routes, List<String> names) {
    if (_mapController == null) return;
    
    _mapController!.clearLines();
    _mapController!.clearSymbols();

    for (int i = 0; i < routes.length; i++) {
      if (routes[i].isNotEmpty) {
        _mapController!.addLine(
          LineOptions(
            geometry: routes[i],
            lineColor: _getRouteColorHex(i),
            lineWidth: 3.0,
            lineOpacity: 0.7,
          ),
        );

        _mapController!.addSymbol(
          SymbolOptions(
            geometry: routes[i].first,
            iconImage: "marker-15",
            iconColor: "#00FF88", // Green for start
            textField: "${names[i]} - Start",
            textOffset: const Offset(0, 2),
            textColor: "#FFFFFF",
          ),
        );

        _mapController!.addSymbol(
          SymbolOptions(
            geometry: routes[i].last,
            iconImage: "marker-15",
            iconColor: "#FF4444", // Red for end
            textField: "${names[i]} - End",
            textOffset: const Offset(0, 2),
            textColor: "#FFFFFF",
          ),
        );
      }
    }

    // Fit camera to show all routes
    if (routes.isNotEmpty && routes.any((route) => route.isNotEmpty)) {
      _fitCameraToRoutes(routes);
    }
  }

  String _getRouteColorHex(int index) {
    final colors = ["#00D4FF", "#FF4444", "#00FF88", "#7C4DFF", "#FF8800"];
    return colors[index % colors.length];
  }

  void _fitCameraToRoutes(List<List<LatLng>> routes) {
    if (routes.isEmpty || routes.every((route) => route.isEmpty)) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final route in routes) {
      for (final point in route) {
        minLat = minLat < point.latitude ? minLat : point.latitude;
        maxLat = maxLat > point.latitude ? maxLat : point.latitude;
        minLng = minLng < point.longitude ? minLng : point.longitude;
        maxLng = maxLng > point.longitude ? maxLng : point.longitude;
      }
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        top: 50,
        left: 50,
        bottom: 50,
        right: 50,
      ),
    );
  }

  void _showEndRideDialog(RideProvider rideProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Ride'),
        content: const Text('Are you sure you want to end the current ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              rideProvider.endRide();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ride saved!')),
              );
            },
            child: const Text('End Ride'),
          ),
        ],
      ),
    );
  }

  void _showRideSelectionDialog() {
    final rideProvider = context.read<RideProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Ride to View'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: rideProvider.rides.length,
            itemBuilder: (context, index) {
              final ride = rideProvider.rides[index];
              return ListTile(
                title: Text('Ride ${index + 1}'),
                subtitle: Text(
                  '${UnitConverter.formatDistance(ride.distance)} • ${_formatDuration(ride.duration)}',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRouteOnMap([ride.route], ['Ride ${index + 1}']);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${secs}s';
    }
  }
}
