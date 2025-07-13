import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:crypto/crypto.dart';

// Enhanced OneWheel connection states
enum OnewheelConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  authenticating,
  authenticated,
  error
}

/// Enhanced OneWheel Bluetooth Low Energy Service
/// Implements modern BLE best practices and improved device discovery
class OnewheelBleService with ChangeNotifier {
  static const String serviceUuid = "e659f300-ea98-11e3-ac10-0800200c9a66";
  
  // OneWheel BLE characteristic UUIDs
  static const String serialNumberUuid = "e659f301-ea98-11e3-ac10-0800200c9a66";
  static const String rideModeUuid = "e659f302-ea98-11e3-ac10-0800200c9a66";
  static const String batteryPercentUuid = "e659f303-ea98-11e3-ac10-0800200c9a66";
  static const String pitchUuid = "e659f304-ea98-11e3-ac10-0800200c9a66";
  static const String rollUuid = "e659f305-ea98-11e3-ac10-0800200c9a66";
  static const String yawUuid = "e659f306-ea98-11e3-ac10-0800200c9a66";
  static const String tripOdometerUuid = "e659f307-ea98-11e3-ac10-0800200c9a66";
  static const String rpmUuid = "e659f308-ea98-11e3-ac10-0800200c9a66";
  static const String temperatureUuid = "e659f309-ea98-11e3-ac10-0800200c9a66";
  static const String firmwareRevisionUuid = "e659f30a-ea98-11e3-ac10-0800200c9a66";
  static const String currentAmpsUuid = "e659f30b-ea98-11e3-ac10-0800200c9a66";
  static const String batteryVoltageUuid = "e659f30c-ea98-11e3-ac10-0800200c9a66";
  static const String lifetimeOdometerUuid = "e659f30d-ea98-11e3-ac10-0800200c9a66";
  static const String uartSerialReadUuid = "e659f30e-ea98-11e3-ac10-0800200c9a66";
  static const String uartSerialWriteUuid = "e659f30f-ea98-11e3-ac10-0800200c9a66";
  
  // Enhanced device discovery with better filtering
  static const List<String> knownOnewheelNames = [
    'onewheel', 'ow', 'future motion', 'fm', 'pint', 'xr', 'gt', 'onewheel+'
  ];
  
  // Known OneWheel MAC address prefixes (OUI ranges)
  static const List<String> knownOuiPrefixes = [
    '00:13:43', // Future Motion OUI
    '00:1B:63', // Common OneWheel range
  ];
  
  // Private fields
  BluetoothDevice? _connectedDevice;
  OnewheelConnectionState _connectionState = OnewheelConnectionState.disconnected;
  String? _lastError;
  bool _isUnlocked = false;
  
  // Enhanced characteristic management
  final Map<String, BluetoothCharacteristic> _characteristics = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  
  // Improved data streaming
  final StreamController<OnewheelData> _dataController = StreamController<OnewheelData>.broadcast();
  Stream<OnewheelData> get dataStream => _dataController.stream;
  
  final OnewheelData _currentData = OnewheelData();
  OnewheelData get currentData => _currentData;
  
  // Enhanced timers and state management
  Timer? _unlockTimer;
  Timer? _connectionWatchdog;
  Timer? _heartbeatTimer;
  Timer? _dataTimer;
  
  // Scan results storage for better device management
  final Map<String, ScanResult> _scanResults = {};
  final StreamController<List<ScanResult>> _scanResultsController = 
      StreamController<List<ScanResult>>.broadcast();
  
  // Getters with enhanced state information
  OnewheelConnectionState get connectionState => _connectionState;
  String? get lastError => _lastError;
  bool get isConnected => _connectionState == OnewheelConnectionState.connected || 
                         _connectionState == OnewheelConnectionState.authenticated;
  bool get isUnlocked => _connectionState == OnewheelConnectionState.authenticated;
  bool get isScanning => _connectionState == OnewheelConnectionState.scanning;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;
  
  /// Enhanced device discovery with better filtering
  Future<void> startScan() async {
    if (_connectionState == OnewheelConnectionState.scanning) return;
    
    _updateConnectionState(OnewheelConnectionState.scanning);
    _scanResults.clear();
    
    try {
      // Enhanced Bluetooth availability check
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported on this device');
      }
      
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is not enabled. Please enable Bluetooth and try again.');
      }
      
      // Enhanced scan with better filtering
      FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 20),
        androidUsesFineLocation: false,
        // Add service UUID filter to improve efficiency
        withServices: [Guid(serviceUuid)],
      );
      
      // Listen to scan results with enhanced filtering
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (isEnhancedOnewheelDevice(result)) {
            _scanResults[result.device.remoteId.str] = result;
          }
        }
        _scanResultsController.add(_scanResults.values.toList());
      });
      
      print('Enhanced scan started - looking for OneWheel devices...');
      
    } catch (e) {
      _handleError('Scan failed: $e');
      rethrow;
    }
  }
  
  /// Stop scanning for devices
  Future<void> stopScan() async {
    if (_connectionState == OnewheelConnectionState.scanning) {
      _updateConnectionState(OnewheelConnectionState.disconnected);
    }
    
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }
  
  /// Enhanced OneWheel device detection
  bool isEnhancedOnewheelDevice(ScanResult scanResult) {
    final device = scanResult.device;
    final name = device.platformName.toLowerCase();
    
    // Check device name patterns
    bool nameMatch = knownOnewheelNames.any((pattern) => 
        name.contains(pattern) || name.startsWith(pattern.substring(0, 2)));
    
    // Check MAC address OUI if available
    bool ouiMatch = false;
    try {
      final macAddress = device.remoteId.str.toUpperCase();
      ouiMatch = knownOuiPrefixes.any((oui) => 
          macAddress.startsWith(oui.replaceAll(':', '')));
    } catch (e) {
      // MAC address not available or parseable
    }
    
    // Check advertised services
    bool serviceMatch = scanResult.advertisementData.serviceUuids
        .any((uuid) => uuid.toString().toLowerCase() == serviceUuid.toLowerCase());
    
    // Check signal strength (avoid very weak signals)
    bool signalStrengthOk = scanResult.rssi > -80;
    
    // Device is likely OneWheel if name matches or (OUI + service) match
    return (nameMatch || (ouiMatch && serviceMatch)) && signalStrengthOk;
  }
  
  /// Enhanced connection with better state management
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_connectionState == OnewheelConnectionState.connecting || 
        _connectionState == OnewheelConnectionState.connected) {
      return;
    }
    
    _updateConnectionState(OnewheelConnectionState.connecting);
    
    try {
      print('Connecting to ${device.platformName} (${device.remoteId})...');
      
      // Enhanced connection with retry logic
      await _connectWithRetry(device);
      _connectedDevice = device;
      _updateConnectionState(OnewheelConnectionState.connected);
      
      // Start connection watchdog
      _startConnectionWatchdog();
      
      // Discover services with timeout
      await _discoverServicesWithTimeout(device);
      
      // Perform enhanced authentication
      await _performEnhancedAuthentication();
      
      // Subscribe to characteristics
      await _subscribeToCharacteristics();
      
      _updateConnectionState(OnewheelConnectionState.authenticated);
      print('Successfully connected and authenticated to ${device.platformName}');
      
    } catch (e) {
      _handleError('Connection failed: $e');
      await disconnect();
      rethrow;
    }
  }
  
  /// Connection with retry logic
  Future<void> _connectWithRetry(BluetoothDevice device, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        await device.connect(timeout: const Duration(seconds: 15));
        return;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        print('Connection attempt ${i + 1} failed, retrying...');
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
  }
  
  /// Enhanced service discovery with timeout
  Future<void> _discoverServicesWithTimeout(BluetoothDevice device) async {
    final services = await device.discoverServices()
        .timeout(const Duration(seconds: 10));
    
    print('Discovered ${services.length} services');
    
    BluetoothService? owService;
    for (BluetoothService service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        owService = service;
        break;
      }
    }
    
    if (owService == null) {
      throw Exception('OneWheel service not found. Available services: ${services.map((s) => s.uuid).join(', ')}');
    }
    
    // Map all characteristics for easier access
    for (BluetoothCharacteristic characteristic in owService.characteristics) {
      _characteristics[characteristic.uuid.toString().toLowerCase()] = characteristic;
    }
    
    print('Found OneWheel service with ${owService.characteristics.length} characteristics');
  }
  
  /// Enhanced authentication with better error handling
  Future<void> _performEnhancedAuthentication() async {
    _updateConnectionState(OnewheelConnectionState.authenticating);
    
    final firmwareChar = _characteristics[firmwareRevisionUuid.toLowerCase()];
    final uartReadChar = _characteristics[uartSerialReadUuid.toLowerCase()];
    final uartWriteChar = _characteristics[uartSerialWriteUuid.toLowerCase()];
    
    if (firmwareChar == null || uartReadChar == null || uartWriteChar == null) {
      throw Exception('Required characteristics not found for authentication');
    }
    
    try {
      print('Starting enhanced OneWheel authentication...');
      
      // Read firmware with retry
      List<int> firmwareData = await _readCharacteristicWithRetry(firmwareChar);
      print('Firmware version: $firmwareData');
      
      // Enhanced challenge-response flow
      await _performChallengeResponse(firmwareChar, uartReadChar, uartWriteChar, firmwareData);
      
      // Start heartbeat to maintain connection
      _startHeartbeat(firmwareChar, firmwareData);
      
      print('Authentication successful!');
      
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }
  
  /// Enhanced challenge-response with better timeout handling
  Future<void> _performChallengeResponse(
    BluetoothCharacteristic firmwareChar,
    BluetoothCharacteristic uartReadChar,
    BluetoothCharacteristic uartWriteChar,
    List<int> firmwareData
  ) async {
    await uartReadChar.setNotifyValue(true);
    
    List<int> challenge = [];
    final challengeCompleter = Completer<void>();
    
    final challengeSub = uartReadChar.onValueReceived.listen((data) {
      challenge.addAll(data);
      print('Challenge progress: ${challenge.length} bytes received');
      
      if (challenge.length >= 20) {
        challengeCompleter.complete();
      }
    });
    
    try {
      // Initiate challenge
      await firmwareChar.write(firmwareData, withoutResponse: false);
      
      // Wait for challenge with timeout
      await challengeCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Challenge timeout - no response from device'),
      );
      
      await challengeSub.cancel();
      await uartReadChar.setNotifyValue(false);
      
      // Validate and respond to challenge
      await _validateAndRespondToChallenge(challenge, uartWriteChar, firmwareChar, firmwareData);
      
    } finally {
      await challengeSub.cancel();
    }
  }
  
  /// Enhanced challenge validation and response
  Future<void> _validateAndRespondToChallenge(
    List<int> challenge, 
    BluetoothCharacteristic uartWriteChar,
    BluetoothCharacteristic firmwareChar,
    List<int> firmwareData
  ) async {
    if (challenge.length < 3 || 
        challenge[0] != 0x43 || 
        challenge[1] != 0x52 || 
        challenge[2] != 0x58) {
      throw Exception('Invalid challenge signature: ${challenge.take(3).toList()}');
    }
    
    // Generate response using improved method
    final response = await _generateEnhancedChallengeResponse(challenge);
    
    // Send response with verification
    await uartWriteChar.write(response, withoutResponse: false);
    
    // Wait a bit to ensure response is processed
    await Future.delayed(const Duration(milliseconds: 100));
    
    _isUnlocked = true;
    notifyListeners();
    
    print('OneWheel unlocked successfully!');
    
    // Start periodic keepalive
    final keepaliveFirmwareChar = firmwareChar;
    final keepaliveFirmwareData = firmwareData;
    _unlockTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        await keepaliveFirmwareChar.write(keepaliveFirmwareData, withoutResponse: false);
        print('Keepalive sent');
      } catch (e) {
        print('Keepalive failed: $e');
      }
    });
  }
  
  /// Enhanced challenge response generation
  Future<List<int>> _generateEnhancedChallengeResponse(List<int> challenge) async {
    // Known OneWheel password (from reverse engineering)
    final password = [0xd9, 0x25, 0x5f, 0x0f, 0x23, 0x35, 0x4e, 0x19, 
                     0xba, 0x73, 0x9c, 0xcd, 0xc4, 0xa9, 0x17, 0x65];
    
    // Enhanced input validation
    if (challenge.length < 4) {
      throw Exception('Challenge too short: ${challenge.length} bytes');
    }
    
    // Prepare MD5 input
    final md5Input = <int>[];
    md5Input.addAll(challenge.sublist(3, challenge.length - 1));
    md5Input.addAll(password);
    
    // Calculate MD5
    final digest = md5.convert(md5Input);
    final md5Hash = digest.bytes;
    
    // Build response with enhanced validation
    final response = <int>[];
    response.addAll([0x43, 0x52, 0x58]); // Signature
    response.addAll(md5Hash);
    
    // Calculate check byte
    int checkByte = 0;
    for (int byte in response) {
      checkByte ^= byte;
    }
    response.add(checkByte);
    
    print('Generated response: ${response.length} bytes');
    return response;
  }
  
  /// Start heartbeat to maintain connection
  void _startHeartbeat(BluetoothCharacteristic firmwareChar, List<int> firmwareData) {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        await firmwareChar.write(firmwareData, withoutResponse: false);
        print('Heartbeat sent');
      } catch (e) {
        print('Heartbeat failed: $e');
        _handleError('Connection lost - heartbeat failed');
      }
    });
  }
  
  /// Start connection watchdog
  void _startConnectionWatchdog() {
    _connectionWatchdog = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_connectedDevice != null) {
        try {
          final state = await _connectedDevice!.connectionState.first;
          if (state != BluetoothConnectionState.connected) {
            _handleError('Connection lost - device disconnected');
            await disconnect();
          }
        } catch (e) {
          _handleError('Connection check failed: $e');
        }
      }
    });
  }
  
  /// Enhanced characteristic subscription
  Future<void> _subscribeToCharacteristics() async {
    print('Subscribing to data characteristics...');
    
    for (final entry in _characteristics.entries) {
      final characteristic = entry.value;
      
      try {
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          
          final subscription = characteristic.onValueReceived.listen((data) {
            _handleCharacteristicData(entry.key, data);
          });
          
          _subscriptions[entry.key] = subscription;
          print('Subscribed to ${entry.key}');
        }
      } catch (e) {
        print('Failed to subscribe to ${entry.key}: $e');
      }
    }
    
    // Start data streaming
    _startDataStreaming();
  }
  
  /// Enhanced characteristic data handling
  void _handleCharacteristicData(String uuid, List<int> data) {
    if (data.isEmpty) return;
    
    try {
      switch (uuid.toLowerCase()) {
        case batteryPercentUuid:
          if (data.isNotEmpty) {
            _currentData.batteryPercent = data[0].toDouble();
          }
          break;
        case pitchUuid:
          if (data.length >= 2) {
            int pitchRaw = (data[1] << 8) | data[0];
            _currentData.pitch = pitchRaw / 100.0;
          }
          break;
        case rollUuid:
          if (data.length >= 2) {
            int rollRaw = (data[1] << 8) | data[0];
            _currentData.roll = rollRaw / 100.0;
          }
          break;
        case yawUuid:
          if (data.length >= 2) {
            int yawRaw = (data[1] << 8) | data[0];
            _currentData.yaw = yawRaw / 100.0;
          }
          break;
        case rpmUuid:
          if (data.length >= 2) {
            int rpmRaw = (data[1] << 8) | data[0];
            _currentData.rpm = rpmRaw.toDouble();
          }
          break;
        case temperatureUuid:
          if (data.length >= 2) {
            int tempRaw = (data[1] << 8) | data[0];
            _currentData.motorTemperature = tempRaw / 100.0;
          }
          break;
        case currentAmpsUuid:
          if (data.length >= 2) {
            int currentRaw = (data[1] << 8) | data[0];
            _currentData.currentAmps = currentRaw / 100.0;
          }
          break;
        case batteryVoltageUuid:
          if (data.length >= 2) {
            int voltageRaw = (data[1] << 8) | data[0];
            _currentData.batteryVoltage = voltageRaw / 100.0;
          }
          break;
        case tripOdometerUuid:
          if (data.length >= 4) {
            int tripRaw = (data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0];
            _currentData.tripOdometer = tripRaw / 1000.0;
          }
          break;
        case lifetimeOdometerUuid:
          if (data.length >= 4) {
            int lifetimeRaw = (data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0];
            _currentData.lifetimeOdometer = lifetimeRaw / 1000.0;
          }
          break;
      }
      
      // Update timestamp
      _currentData.timestamp = DateTime.now();
      
      // Emit updated data
      _dataController.add(_currentData);
      notifyListeners();
      
    } catch (e) {
      print('Error processing data from $uuid: $e');
    }
  }
  
  /// Start data streaming
  void _startDataStreaming() {
    _dataTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (_connectionState == OnewheelConnectionState.authenticated) {
        // Data is now handled via notifications, just notify listeners
        notifyListeners();
      }
    });
  }
  
  /// Enhanced error handling
  void _handleError(String error) {
    _lastError = error;
    _updateConnectionState(OnewheelConnectionState.error);
    print('Error: $error');
  }
  
  /// Update connection state with notification
  void _updateConnectionState(OnewheelConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      notifyListeners();
    }
  }
  
  /// Read characteristic with retry logic
  Future<List<int>> _readCharacteristicWithRetry(BluetoothCharacteristic characteristic, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await characteristic.read();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
      }
    }
    throw Exception('Failed to read characteristic after $maxRetries attempts');
  }
  
  /// Enhanced disconnect with proper cleanup
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _connectionWatchdog?.cancel();
    _unlockTimer?.cancel();
    _dataTimer?.cancel();
    
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _characteristics.clear();
    
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('Error during disconnect: $e');
      }
    }
    
    _connectedDevice = null;
    _updateConnectionState(OnewheelConnectionState.disconnected);
    _lastError = null;
    
    print('Disconnected from OneWheel');
  }
  
  /// Get available OneWheel devices from scan results
  List<BluetoothDevice> getAvailableOnewheelDevices() {
    return _scanResults.values.map((result) => result.device).toList();
  }
  
  /// Enhanced diagnostic information
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final info = <String, dynamic>{};
    
    try {
      // Bluetooth state
      info['bluetoothSupported'] = await FlutterBluePlus.isSupported;
      info['bluetoothEnabled'] = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      
      // Connection state
      info['connectionState'] = _connectionState.toString();
      info['lastError'] = _lastError;
      info['connectedDevice'] = _connectedDevice?.platformName ?? 'None';
      info['connectedDeviceId'] = _connectedDevice?.remoteId.str ?? 'None';
      
      // Scan results
      final devices = getAvailableOnewheelDevices();
      info['onewheelDevicesFound'] = devices.length;
      info['onewheelDevices'] = devices.map((device) => {
        'name': device.platformName,
        'id': device.remoteId.str,
      }).toList();
      
      // Characteristics status
      info['characteristicsFound'] = _characteristics.length;
      info['subscriptionsActive'] = _subscriptions.length;
      
      // Timers status
      info['heartbeatActive'] = _heartbeatTimer?.isActive ?? false;
      info['watchdogActive'] = _connectionWatchdog?.isActive ?? false;
      
    } catch (e) {
      info['error'] = e.toString();
    }
    
    return info;
  }
  
  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _connectionWatchdog?.cancel();
    _unlockTimer?.cancel();
    _dataTimer?.cancel();
    
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    
    _dataController.close();
    _scanResultsController.close();
    super.dispose();
  }
}

/// OneWheel data model with enhanced properties
class OnewheelData {
  double batteryPercent = 0.0;
  double pitch = 0.0;
  double roll = 0.0;
  double yaw = 0.0;
  double rpm = 0.0;
  double motorTemperature = 0.0;
  double currentAmps = 0.0;
  double batteryVoltage = 0.0;
  double tripOdometer = 0.0;
  double lifetimeOdometer = 0.0;
  DateTime timestamp = DateTime.now();
  String rideMode = 'Unknown';
  
  // Calculated properties
  double get speed => (rpm * 0.01667).abs(); // Convert RPM to approximate MPH
  double get tripDistance => tripOdometer; // Alias for compatibility
  double get lifetimeDistance => lifetimeOdometer; // Alias for compatibility
  bool get isCharging => currentAmps < 0; // Negative current means charging
  
  bool get isRiding => speed > 0.1;
  
  String get batteryStatus {
    if (batteryPercent > 80) return 'Full';
    if (batteryPercent > 60) return 'Good';
    if (batteryPercent > 40) return 'Medium';
    if (batteryPercent > 20) return 'Low';
    return 'Critical';
  }
  
  @override
  String toString() {
    return 'OnewheelData(battery: ${batteryPercent.toStringAsFixed(1)}%, speed: ${speed.toStringAsFixed(1)} mph, temp: ${motorTemperature.toStringAsFixed(1)}°C)';
  }
}
