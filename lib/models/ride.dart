import 'package:maplibre_gl/maplibre_gl.dart';

class Ride {
  final String id;
  final String? deviceId; // Device UUID for user association
  final DateTime startTime;
  final DateTime? endTime;
  final double distance;
  final double maxSpeed;
  final double avgSpeed;
  final int duration; // in seconds
  final List<LatLng> route;
  final double? startBattery;
  final double? endBattery;
  final String? notes;

  Ride({
    required this.id,
    this.deviceId,
    required this.startTime,
    this.endTime,
    required this.distance,
    required this.maxSpeed,
    required this.avgSpeed,
    required this.duration,
    required this.route,
    this.startBattery,
    this.endBattery,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'distance': distance,
      'maxSpeed': maxSpeed,
      'avgSpeed': avgSpeed,
      'duration': duration,
      'route': route.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'startBattery': startBattery,
      'endBattery': endBattery,
      'notes': notes,
    };
  }

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      deviceId: json['deviceId'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: json['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          : null,
      distance: json['distance'].toDouble(),
      maxSpeed: json['maxSpeed'].toDouble(),
      avgSpeed: json['avgSpeed'].toDouble(),
      duration: json['duration'],
      route: (json['route'] as List)
          .map((point) => LatLng(
                point['latitude'],
                point['longitude'],
              ))
          .toList(),
      startBattery: json['startBattery']?.toDouble(),
      endBattery: json['endBattery']?.toDouble(),
      notes: json['notes'],
    );
  }

  Ride copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    double? maxSpeed,
    double? avgSpeed,
    int? duration,
    List<LatLng>? route,
    double? startBattery,
    double? endBattery,
    String? notes,
  }) {
    return Ride(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      duration: duration ?? this.duration,
      route: route ?? this.route,
      startBattery: startBattery ?? this.startBattery,
      endBattery: endBattery ?? this.endBattery,
      notes: notes ?? this.notes,
    );
  }
}
