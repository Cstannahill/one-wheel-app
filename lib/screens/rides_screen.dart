import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ride_provider.dart';
import '../models/ride.dart';
import '../utils/unit_converter.dart';

class RidesScreen extends StatelessWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<RideProvider>(
        builder: (context, rideProvider, child) {
          if (rideProvider.rides.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.route,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No rides yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start riding to track your adventures!',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final sortedRides = List<Ride>.from(rideProvider.rides)
            ..sort((a, b) => b.startTime.compareTo(a.startTime));

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total Rides',
                          rideProvider.totalRides.toString(),
                          Icons.route,
                          context,
                        ),
                        _buildSummaryItem(
                          'Total Distance',
                          UnitConverter.formatDistance(rideProvider.totalDistance),
                          Icons.straighten,
                          context,
                        ),
                        _buildSummaryItem(
                          'Total Time',
                          '${rideProvider.totalTime.toStringAsFixed(1)}h',
                          Icons.timer,
                          context,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Rides List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedRides.length,
                  itemBuilder: (context, index) {
                    final ride = sortedRides[index];
                    return RideCard(
                      ride: ride,
                      onDelete: () => _showDeleteDialog(context, ride, rideProvider),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
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

  void _showDeleteDialog(BuildContext context, Ride ride, RideProvider rideProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Ride'),
          content: const Text('Are you sure you want to delete this ride? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                rideProvider.deleteRide(ride.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride deleted')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onDelete;

  const RideCard({
    super.key,
    required this.ride,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.directions_bike,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          _formatDate(ride.startTime),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${UnitConverter.formatDistance(ride.distance)} • ${_formatDuration(ride.duration)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Ride Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Max Speed',
                      '${ride.maxSpeed.toStringAsFixed(1)} mph',
                      Icons.speed,
                    ),
                    _buildStatColumn(
                      'Avg Speed',
                      '${ride.avgSpeed.toStringAsFixed(1)} mph',
                      Icons.trending_up,
                    ),
                    _buildStatColumn(
                      'Distance',
                      UnitConverter.formatDistance(ride.distance),
                      Icons.straighten,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Battery Info
                if (ride.startBattery != null || ride.endBattery != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (ride.startBattery != null)
                        _buildStatColumn(
                          'Start Battery',
                          '${ride.startBattery!.toInt()}%',
                          Icons.battery_full,
                        ),
                      if (ride.endBattery != null)
                        _buildStatColumn(
                          'End Battery',
                          '${ride.endBattery!.toInt()}%',
                          Icons.battery_alert,
                        ),
                      if (ride.startBattery != null && ride.endBattery != null)
                        _buildStatColumn(
                          'Battery Used',
                          '${(ride.startBattery! - ride.endBattery!).toInt()}%',
                          Icons.battery_charging_full,
                        ),
                    ],
                  ),
                
                // Time Info
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Start Time',
                      _formatTime(ride.startTime),
                      Icons.play_arrow,
                    ),
                    if (ride.endTime != null)
                      _buildStatColumn(
                        'End Time',
                        _formatTime(ride.endTime!),
                        Icons.stop,
                      ),
                    _buildStatColumn(
                      'Duration',
                      _formatDuration(ride.duration),
                      Icons.timer,
                    ),
                  ],
                ),
                
                // Notes
                if (ride.notes != null && ride.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride.notes!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
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
