import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../services/onewheel_ble_service.dart';

class OnewheelConnectionScreen extends StatefulWidget {
  const OnewheelConnectionScreen({super.key});

  @override
  State<OnewheelConnectionScreen> createState() => _OnewheelConnectionScreenState();
}

class _OnewheelConnectionScreenState extends State<OnewheelConnectionScreen> {
  List<ScanResult> _scanResults = [];
  List<BluetoothDevice> _onewheelDevices = [];
  bool _isBluetoothOn = false;
  bool _showAllDevices = false;
  Map<String, dynamic>? _diagnosticInfo;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    _listenToScanResults();
    _loadDiagnosticInfo();
  }

  void _checkBluetoothState() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    final isOn = adapterState == BluetoothAdapterState.on;
    setState(() {
      _isBluetoothOn = isOn;
    });
    
    if (isOn) {
      _startScan();
    }
  }

  void _listenToScanResults() {
    final bleService = Provider.of<OnewheelBleService>(context, listen: false);
    
    // Listen to enhanced scan results
    bleService.scanResults.listen((results) {
      setState(() {
        _scanResults = results;
        _onewheelDevices = results.map((r) => r.device).toList();
      });
    });
  }

  void _loadDiagnosticInfo() async {
    final bleService = Provider.of<OnewheelBleService>(context, listen: false);
    final info = await bleService.getDiagnosticInfo();
    setState(() {
      _diagnosticInfo = info;
    });
  }

  void _startScan() async {
    final bleService = Provider.of<OnewheelBleService>(context, listen: false);
    try {
      await bleService.startScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start scan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopScan() async {
    final bleService = Provider.of<OnewheelBleService>(context, listen: false);
    await bleService.stopScan();
  }

  void _connectToDevice(BluetoothDevice device) async {
    final bleService = Provider.of<OnewheelBleService>(context, listen: false);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting to OneWheel...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await bleService.connectToDevice(device);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.platformName}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Go back to main screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOnewheelDeviceCard(BluetoothDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: const Color(0xFF1A1A1A),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Icon(
            Icons.skateboarding, // Use skateboarding icon as closest to OneWheel
            color: Color(0xFF00D4FF),
          ),
        ),
        title: Text(
          device.platformName.isNotEmpty ? device.platformName : 'OneWheel Device',
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device ID: ${device.remoteId}',
              style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
            ),
            Text(
              'RSSI: ${_getRssiForDevice(device)}',
              style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _connectToDevice(device),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            foregroundColor: const Color(0xFF0A0A0A),
          ),
          child: const Text('Connect'),
        ),
      ),
    );
  }

  Widget _buildGenericDeviceCard(ScanResult result) {
    final device = result.device;
    final bleService = Provider.of<OnewheelBleService>(context, listen: false);
    final isOnewheel = bleService.isEnhancedOnewheelDevice(result);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      color: isOnewheel ? const Color(0xFF1A1A1A) : const Color(0xFF0F0F0F),
      child: ListTile(
        leading: Icon(
          isOnewheel ? Icons.skateboarding : Icons.bluetooth,
          color: isOnewheel ? const Color(0xFF00D4FF) : Colors.grey[600],
          size: 20,
        ),
        title: Text(
          device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
          style: TextStyle(
            color: isOnewheel ? const Color(0xFFE0E0E0) : Colors.grey[500],
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${device.remoteId} • RSSI: ${result.rssi}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: isOnewheel ? TextButton(
          onPressed: () => _connectToDevice(device),
          child: const Text('Connect', style: TextStyle(fontSize: 12)),
        ) : null,
      ),
    );
  }

  int _getRssiForDevice(BluetoothDevice device) {
    final result = _scanResults.firstWhere(
      (r) => r.device.remoteId == device.remoteId,
      orElse: () => ScanResult(
        device: device, 
        rssi: 0, 
        advertisementData: AdvertisementData(
          advName: '',
          appearance: 0,
          txPowerLevel: 0,
          connectable: true,
          manufacturerData: {},
          serviceData: {},
          serviceUuids: [],
        ),
        timeStamp: DateTime.now(),
      ),
    );
    return result.rssi;
  }

  void _showDiagnosticDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bluetooth Diagnostic Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_diagnosticInfo != null) ...[
                _buildDiagnosticItem('Bluetooth Available', _diagnosticInfo!['bluetoothAvailable']?.toString() ?? 'Unknown'),
                _buildDiagnosticItem('Bluetooth On', _diagnosticInfo!['bluetoothOn']?.toString() ?? 'Unknown'),
                _buildDiagnosticItem('Total Devices Found', _diagnosticInfo!['totalDevicesFound']?.toString() ?? '0'),
                _buildDiagnosticItem('OneWheel Devices Found', _diagnosticInfo!['onewheelDevicesFound']?.toString() ?? '0'),
                const SizedBox(height: 8),
                const Text('OneWheel Device Names:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...(_diagnosticInfo!['onewheelDeviceNames'] as List<dynamic>? ?? []).map((name) => Text('• $name')),
                const SizedBox(height: 8),
                const Text('All Device Names:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...(_diagnosticInfo!['allDeviceNames'] as List<dynamic>? ?? []).take(10).map((name) => Text('• $name', style: const TextStyle(fontSize: 12))),
              ] else ...[
                const Text('Loading diagnostic information...'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadDiagnosticInfo();
            },
            child: const Text('Refresh'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect OneWheel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<OnewheelBleService>(
            builder: (context, bleService, child) {
              if (bleService.isScanning) {
                return TextButton.icon(
                  onPressed: _stopScan,
                  icon: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: const Text('Stop'),
                );
              } else {
                return TextButton.icon(
                  onPressed: _isBluetoothOn ? _startScan : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan'),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Bluetooth status card
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: Icon(
                _isBluetoothOn ? Icons.bluetooth : Icons.bluetooth_disabled,
                color: _isBluetoothOn ? Colors.blue : Colors.grey,
                size: 32,
              ),
              title: Text(_isBluetoothOn ? 'Bluetooth On' : 'Bluetooth Off'),
              subtitle: Text(_isBluetoothOn 
                ? 'Ready to scan for OneWheel devices' 
                : 'Please enable Bluetooth to continue'),
              trailing: _isBluetoothOn 
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.warning, color: Colors.orange),
            ),
          ),
          
          // Current connection status
          Consumer<OnewheelBleService>(
            builder: (context, bleService, child) {
              if (bleService.isConnected) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    title: Text('Connected to ${bleService.connectedDevice?.platformName}'),
                    subtitle: Text(bleService.isUnlocked ? 'Unlocked and ready' : 'Connected, unlocking...'),
                    trailing: TextButton.icon(
                      onPressed: () async {
                        await bleService.disconnect();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Disconnected from OneWheel'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Disconnect'),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // OneWheel Devices Section
          if (_onewheelDevices.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'OneWheel Devices Found (${_onewheelDevices.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF00D4FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._onewheelDevices.map((device) => _buildOnewheelDeviceCard(device)),
            const SizedBox(height: 16),
          ],
          
          // Instructions when no OneWheel devices found
          if (_isBluetoothOn && _onewheelDevices.isEmpty) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No OneWheel devices found',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Make sure your OneWheel is:\n• Powered on\n• Within 30 feet\n• Not connected to another device',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _startScan();
                        _loadDiagnosticInfo();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Scan Again'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _showDiagnosticDialog(),
                      child: const Text('View Troubleshooting Info'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Bluetooth disabled instructions
          if (!_isBluetoothOn) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bluetooth is disabled',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enable Bluetooth to connect to your OneWheel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Note: turnOn() is deprecated. In production apps,
                        // you should guide users to enable Bluetooth manually
                        try {
                          await FlutterBluePlus.turnOn();
                        } catch (e) {
                          // Fallback: Show system settings or instruction dialog
                          print('Cannot programmatically enable Bluetooth: $e');
                        }
                        _checkBluetoothState();
                      },
                      icon: const Icon(Icons.bluetooth),
                      label: const Text('Enable Bluetooth'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Debug Section Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Show All Devices',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Switch(
                  value: _showAllDevices,
                  onChanged: (value) {
                    setState(() {
                      _showAllDevices = value;
                    });
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showDiagnosticDialog(),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Debug Info'),
                ),
              ],
            ),
          ),
          
          // All Devices Section (when debug enabled)
          if (_showAllDevices && _scanResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'All Devices (${_scanResults.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ..._scanResults.map((result) => _buildGenericDeviceCard(result)),
          ],
        ],
      ),
    );
  }
}
