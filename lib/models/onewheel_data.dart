import 'package:flutter/foundation.dart';

/// Data model for OneWheel telemetry data
class OnewheelData {
  double? batteryPercent;
  double? batteryVoltage;
  double? currentAmps;
  double? temperature;
  double? pitch;
  double? roll;
  double? yaw;
  double? rpm;
  double? speed;
  double? tripDistance;
  double? lifetimeDistance;
  String? serialNumber;
  String? firmwareVersion;
  int? rideMode;
  DateTime timestamp = DateTime.now();

  OnewheelData({
    this.batteryPercent,
    this.batteryVoltage,
    this.currentAmps,
    this.temperature,
    this.pitch,
    this.roll,
    this.yaw,
    this.rpm,
    this.speed,
    this.tripDistance,
    this.lifetimeDistance,
    this.serialNumber,
    this.firmwareVersion,
    this.rideMode,
  });

  /// Create a copy of the data with updated values
  OnewheelData copyWith({
    double? batteryPercent,
    double? batteryVoltage,
    double? currentAmps,
    double? temperature,
    double? pitch,
    double? roll,
    double? yaw,
    double? rpm,
    double? speed,
    double? tripDistance,
    double? lifetimeDistance,
    String? serialNumber,
    String? firmwareVersion,
    int? rideMode,
  }) {
    return OnewheelData(
      batteryPercent: batteryPercent ?? this.batteryPercent,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      currentAmps: currentAmps ?? this.currentAmps,
      temperature: temperature ?? this.temperature,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      yaw: yaw ?? this.yaw,
      rpm: rpm ?? this.rpm,
      speed: speed ?? this.speed,
      tripDistance: tripDistance ?? this.tripDistance,
      lifetimeDistance: lifetimeDistance ?? this.lifetimeDistance,
      serialNumber: serialNumber ?? this.serialNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      rideMode: rideMode ?? this.rideMode,
    );
  }

  /// Convert rpm to approximate speed in mph
  /// This is a rough calculation and will vary by wheel size
  double? get speedFromRpm {
    if (rpm == null) return null;
    // For OneWheel GT-S with standard tire
    return rpm! * 0.0055; 
  }

  @override
  String toString() {
    return 'OnewheelData{batteryPercent: $batteryPercent%, voltage: $batteryVoltage, '
           'temperature: $temperature°F, rpm: $rpm, speed: $speed mph}';
  }
}