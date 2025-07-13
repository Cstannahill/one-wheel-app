class OneWheelStats {
  final double speed;
  final double battery;
  final double temperature;
  final double voltage;
  final double current;
  final double rpm;
  final double pitch;
  final double roll;
  final double yaw;
  final bool isConnected;
  final bool isCharging;
  final double tripDistance;
  final double lifetimeDistance;
  final String rideMode;
  final DateTime lastUpdated;

  OneWheelStats({
    required this.speed,
    required this.battery,
    required this.temperature,
    required this.voltage,
    required this.current,
    required this.rpm,
    required this.pitch,
    required this.roll,
    required this.yaw,
    this.isConnected = false,
    this.isCharging = false,
    this.tripDistance = 0.0,
    this.lifetimeDistance = 0.0,
    this.rideMode = 'Classic',
    required this.lastUpdated,
  });

  OneWheelStats copyWith({
    double? speed,
    double? battery,
    double? temperature,
    double? voltage,
    double? current,
    double? rpm,
    double? pitch,
    double? roll,
    double? yaw,
    bool? isConnected,
    bool? isCharging,
    double? tripDistance,
    double? lifetimeDistance,
    String? rideMode,
    DateTime? lastUpdated,
  }) {
    return OneWheelStats(
      speed: speed ?? this.speed,
      battery: battery ?? this.battery,
      temperature: temperature ?? this.temperature,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      rpm: rpm ?? this.rpm,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      yaw: yaw ?? this.yaw,
      isConnected: isConnected ?? this.isConnected,
      isCharging: isCharging ?? this.isCharging,
      tripDistance: tripDistance ?? this.tripDistance,
      lifetimeDistance: lifetimeDistance ?? this.lifetimeDistance,
      rideMode: rideMode ?? this.rideMode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Generate dummy data for testing (US units)
  static OneWheelStats generateDummy() {
    final now = DateTime.now();
    return OneWheelStats(
      speed: (3 + (DateTime.now().millisecond % 100) / 5).clamp(0, 15.5), // ~5-25 mph range
      battery: (60 + (DateTime.now().second % 40)).toDouble().clamp(0, 100),
      temperature: (68 + (DateTime.now().second % 30)).toDouble(), // ~68-98°F range
      voltage: (54 + (DateTime.now().millisecond % 100) / 100).clamp(48, 60),
      current: (-5 + (DateTime.now().millisecond % 100) / 10).clamp(-10, 10),
      rpm: (500 + (DateTime.now().millisecond % 1000)).toDouble(),
      pitch: (-5 + (DateTime.now().millisecond % 100) / 10).clamp(-15, 15),
      roll: (-3 + (DateTime.now().millisecond % 60) / 10).clamp(-10, 10),
      yaw: (DateTime.now().millisecond % 360).toDouble(),
      isConnected: true,
      isCharging: false,
      tripDistance: (2.5 + (DateTime.now().minute % 10) / 2), // miles
      lifetimeDistance: 1234.5, // miles
      rideMode: 'Classic',
      lastUpdated: now,
    );
  }
}
