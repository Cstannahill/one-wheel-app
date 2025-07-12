import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:latlong2/latlong.dart' as latlong;
import 'dart:io' show Platform;

/// An adaptive map widget that uses:
/// - MapLibre GL for mobile platforms (Android/iOS) - best performance
/// - Flutter Map for web/desktop platforms - broad compatibility
class AdaptiveMap extends StatefulWidget {
  final latlong.LatLng initialCenter;
  final double initialZoom;
  final Function(dynamic controller)? onMapCreated;
  final bool myLocationEnabled;
  final List<latlong.LatLng> routePoints;
  final VoidCallback? onStyleLoaded;

  const AdaptiveMap({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    this.onMapCreated,
    this.myLocationEnabled = false,
    this.routePoints = const [],
    this.onStyleLoaded,
  });

  @override
  State<AdaptiveMap> createState() => _AdaptiveMapState();
}

class _AdaptiveMapState extends State<AdaptiveMap> {
  late bool _useFlutterMap;

  @override
  void initState() {
    super.initState();
    // Use Flutter Map for web and desktop, MapLibre for mobile
    _useFlutterMap = kIsWeb || (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS));
  }

  @override
  Widget build(BuildContext context) {
    if (_useFlutterMap) {
      return _buildFlutterMap();
    } else {
      return _buildMapLibreMap();
    }
  }

  Widget _buildFlutterMap() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            onMapReady: () {
              widget.onStyleLoaded?.call();
            },
          ),
          children: [
            // Dark theme tile layer using free CartoDB Dark tiles
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              additionalOptions: const {
                'attribution': '© OpenStreetMap contributors, © CartoDB',
              },
              retinaMode: RetinaMode.isHighDensity(context),
            ),
            // Route polyline
            if (widget.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePoints,
                    strokeWidth: 4.0,
                    color: const Color(0xFF00D4FF),
                    borderStrokeWidth: 2.0,
                    borderColor: const Color(0xFF0A0A0A),
                  ),
                ],
              ),
            // Current location marker
            if (widget.myLocationEnabled)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.initialCenter,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0A0A0A),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4FF).withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF0A0A0A),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLibreMap() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: maplibre.MapLibreMap(
          styleString: 'https://demotiles.maplibre.org/style.json',
          onMapCreated: (maplibre.MapLibreMapController controller) {
            widget.onMapCreated?.call(controller);
          },
          initialCameraPosition: maplibre.CameraPosition(
            target: maplibre.LatLng(widget.initialCenter.latitude, widget.initialCenter.longitude),
            zoom: widget.initialZoom,
          ),
          myLocationEnabled: widget.myLocationEnabled,
          myLocationTrackingMode: maplibre.MyLocationTrackingMode.none,
          onStyleLoadedCallback: widget.onStyleLoaded,
          compassEnabled: true,
          annotationOrder: const [
            maplibre.AnnotationType.line,
            maplibre.AnnotationType.symbol,
          ],
        ),
      ),
    );
  }
}
