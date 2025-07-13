import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/ride_provider.dart';
import '../services/onewheel_ble_service.dart';
import '../models/onewheel_stats.dart';
import '../widgets/stat_card.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/speed_gauge.dart';
import '../utils/unit_converter.dart';
import '../screens/onewheel_connection_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late OneWheelStats _dummyStats;

  @override
  void initState() {
    super.initState();
    _dummyStats = OneWheelStats.generateDummy();
    _startDummyDataUpdates();
    
    // Connect BLE service to ride provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleService = context.read<OnewheelBleService>();
      final rideProvider = context.read<RideProvider>();
      rideProvider.setBleService(bleService);
    });
  }

  void _startDummyDataUpdates() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Only update dummy data if BLE is not connected
        final bleService = context.read<OnewheelBleService>();
        if (!bleService.isConnected) {
          setState(() {
            _dummyStats = OneWheelStats.generateDummy();
          });
          context.read<RideProvider>().updateStats(_dummyStats);
        }
        _startDummyDataUpdates();
      }
    });
  }

  // Get current stats - use BLE data if available, otherwise dummy data
  OneWheelStats _getCurrentStats() {
    final rideProvider = context.read<RideProvider>();
    final bleService = context.read<OnewheelBleService>();
    
    if (bleService.isConnected && rideProvider.currentStats != null) {
      return rideProvider.currentStats!;
    }
    return _dummyStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OneWheel Dashboard'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFE0E0E0),
        elevation: 0,
        actions: [
          // OneWheel Connection Status
          Consumer<OnewheelBleService>(
            builder: (context, bleService, child) {
              return IconButton(
                icon: Icon(
                  bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: bleService.isConnected ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OnewheelConnectionScreen(),
                    ),
                  );
                },
              );
            },
          ),
          Consumer<RideProvider>(
            builder: (context, rideProvider, child) {
              return IconButton(
                icon: Icon(
                  rideProvider.isRiding ? Icons.stop : Icons.play_arrow,
                  color: rideProvider.isRiding ? Colors.red : Colors.green,
                ),
                onPressed: () {
                  if (rideProvider.isRiding) {
                    rideProvider.endRide();
                  } else {
                    rideProvider.startRide();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OneWheel Connection Status
            Consumer<OnewheelBleService>(
              builder: (context, bleService, child) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bleService.isConnected 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: bleService.isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                        color: bleService.isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bleService.isConnected ? 'OneWheel Connected' : 'OneWheel Disconnected',
                              style: TextStyle(
                                color: bleService.isConnected ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (bleService.isConnected && bleService.connectedDevice != null)
                              Text(
                                '${bleService.connectedDevice!.platformName} - ${bleService.isUnlocked ? "Unlocked" : "Unlocking..."}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            if (!bleService.isConnected)
                              Text(
                                'Tap to connect your board',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!bleService.isConnected)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const OnewheelConnectionScreen(),
                              ),
                            );
                          },
                          child: const Text('Connect'),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Speed and Battery Row
            Builder(
              builder: (context) {
                final currentStats = _getCurrentStats();
                return Row(
                  children: [
                    Expanded(
                      child: SpeedGauge(
                        speed: currentStats.speed, // Already in MPH
                        maxSpeed: 19, // mph
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BatteryIndicator(
                        percentage: currentStats.battery,
                        voltage: currentStats.voltage,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Builder(
              builder: (context) {
                final currentStats = _getCurrentStats();
                return GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(
                      icon: FontAwesomeIcons.thermometerHalf,
                      title: 'Temperature',
                      value: UnitConverter.formatTemperature(currentStats.temperature),
                      color: _getTemperatureColor(currentStats.temperature),
                    ),
                    StatCard(
                      icon: FontAwesomeIcons.bolt,
                      title: 'Current',
                      value: '${currentStats.current.toStringAsFixed(1)}A',
                      color: _getCurrentColor(currentStats.current),
                    ),
                    StatCard(
                      icon: FontAwesomeIcons.cog,
                      title: 'RPM',
                      value: currentStats.rpm.toInt().toString(),
                      color: Colors.blue,
                    ),
                    StatCard(
                      icon: FontAwesomeIcons.compass,
                      title: 'Pitch',
                      value: '${currentStats.pitch.toStringAsFixed(1)}°',
                      color: _getPitchColor(currentStats.pitch),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Current Ride Info
            Consumer<RideProvider>(
              builder: (context, rideProvider, child) {
                if (rideProvider.isRiding && rideProvider.currentRide != null) {
                  final ride = rideProvider.currentRide!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_bike, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Current Ride',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildRideInfoColumn(
                                'Distance',
                                '${UnitConverter.kmToMiles(ride.distance).toStringAsFixed(1)} mi',
                                FontAwesomeIcons.route,
                              ),
                              _buildRideInfoColumn(
                                'Duration',
                                '${(ride.duration / 60).toInt()}:${((ride.duration % 60).toInt()).toString().padLeft(2, '0')}',
                                FontAwesomeIcons.clock,
                              ),
                              _buildRideInfoColumn(
                                'Avg Speed',
                                '${UnitConverter.kmhToMph(ride.avgSpeed).toStringAsFixed(1)} mph',
                                FontAwesomeIcons.tachometerAlt,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Quick Stats Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Stats',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Consumer<RideProvider>(
                      builder: (context, rideProvider, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildRideInfoColumn(
                              'Total Rides',
                              rideProvider.totalRides.toString(),
                              FontAwesomeIcons.list,
                            ),
                            _buildRideInfoColumn(
                              'Total Distance',
                              '${UnitConverter.kmToMiles(rideProvider.totalDistance).toStringAsFixed(1)} mi',
                              FontAwesomeIcons.mapMarkerAlt,
                            ),
                            _buildRideInfoColumn(
                              'Total Time',
                              '${rideProvider.totalTime.toStringAsFixed(1)}h',
                              FontAwesomeIcons.clock,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideInfoColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp > 140) return Colors.red; // Above 140°F is hot
    if (temp > 120) return Colors.orange; // 120-140°F is warm
    if (temp > 100) return Colors.yellow; // 100-120°F is normal operating
    return Colors.green; // Below 100°F is cool
  }

  Color _getCurrentColor(double current) {
    if (current.abs() > 7) return Colors.red; // High current
    if (current.abs() > 4) return Colors.orange; // Medium current
    return Colors.green; // Low current
  }

  Color _getPitchColor(double pitch) {
    if (pitch.abs() > 10) return Colors.red; // Steep angle
    if (pitch.abs() > 5) return Colors.orange; // Medium angle
    return Colors.green; // Normal angle
  }
}
