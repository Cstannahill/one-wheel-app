import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/ride_provider.dart';
import '../models/onewheel_stats.dart';
import '../widgets/stat_card.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/speed_gauge.dart';
import '../utils/unit_converter.dart';

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
  }

  void _startDummyDataUpdates() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _dummyStats = OneWheelStats.generateDummy();
        });
        context.read<RideProvider>().updateStats(_dummyStats);
        _startDummyDataUpdates();
      }
    });
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
            // Connection Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _dummyStats.isConnected 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _dummyStats.isConnected ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _dummyStats.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    color: _dummyStats.isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _dummyStats.isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color: _dummyStats.isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Speed and Battery Row
            Row(
              children: [
                Expanded(
                  child: SpeedGauge(
                    speed: UnitConverter.kmhToMph(_dummyStats.speed),
                    maxSpeed: 19, // mph (converted from 30 km/h)
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BatteryIndicator(
                    percentage: _dummyStats.battery,
                    voltage: _dummyStats.voltage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
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
                  value: UnitConverter.formatTemperature(_dummyStats.temperature),
                  color: _getTemperatureColor(_dummyStats.temperature),
                ),
                StatCard(
                  icon: FontAwesomeIcons.bolt,
                  title: 'Current',
                  value: '${_dummyStats.current.toStringAsFixed(1)}A',
                  color: _getCurrentColor(_dummyStats.current),
                ),
                StatCard(
                  icon: FontAwesomeIcons.cog,
                  title: 'RPM',
                  value: _dummyStats.rpm.toInt().toString(),
                  color: Colors.blue,
                ),
                StatCard(
                  icon: FontAwesomeIcons.compass,
                  title: 'Pitch',
                  value: '${_dummyStats.pitch.toStringAsFixed(1)}°',
                  color: _getPitchColor(_dummyStats.pitch),
                ),
              ],
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
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildRideStatColumn(
                                'Distance',
                                UnitConverter.formatDistance(ride.distance),
                                Icons.straighten,
                              ),
                              _buildRideStatColumn(
                                'Duration',
                                _formatDuration(ride.duration),
                                Icons.timer,
                              ),
                              _buildRideStatColumn(
                                'Avg Speed',
                                '${ride.avgSpeed.toStringAsFixed(1)} mph',
                                Icons.speed,
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
            const SizedBox(height: 24),

            // Ride Statistics Summary
            Consumer<RideProvider>(
              builder: (context, rideProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride Statistics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildRideStatColumn(
                              'Total Rides',
                              rideProvider.totalRides.toString(),
                              Icons.route,
                            ),
                            _buildRideStatColumn(
                              'Total Distance',
                              UnitConverter.formatDistance(rideProvider.totalDistance),
                              Icons.straighten,
                            ),
                            _buildRideStatColumn(
                              'Total Time',
                              '${rideProvider.totalTime.toStringAsFixed(1)}h',
                              Icons.timer,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getTemperatureColor(double tempFahrenheit) {
    if (tempFahrenheit < 32) return Colors.blue; // Below freezing
    if (tempFahrenheit < 86) return Colors.green; // Nice temp
    if (tempFahrenheit < 122) return Colors.orange; // Getting hot
    return Colors.red; // Too hot
  }

  Color _getCurrentColor(double current) {
    if (current.abs() < 2) return Colors.green;
    if (current.abs() < 5) return Colors.orange;
    return Colors.red;
  }

  Color _getPitchColor(double pitch) {
    if (pitch.abs() < 5) return Colors.green;
    if (pitch.abs() < 10) return Colors.orange;
    return Colors.red;
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
