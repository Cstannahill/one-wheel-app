import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:crypto/crypto.dart';

/// Enhanced OneWheel Bluetooth Low Energy Service
/// Implements modern BLE best practices and improved device discovery
class OnewheelBleService with ChangeNotifier {
  static const String SERVICE_UUID = "e659f300-ea98-11e3-ac10-0800200c9a66";
  
  // Characteristic UUIDs based on reverse engineering
  static const String SERIAL_NUMBER_UUID = "e659f301-ea98-11e3-ac10-0800200c9a66";
  static const String RIDE_MODE_UUID = "e659f302-ea98-11e3-ac10-0800200c9a66";
  static const String BATTERY_PERCENT_UUID = "e659f303-ea98-11e3-ac10-0800200c9a66";
  static const String PITCH_UUID = "e659f307-ea98-11e3-ac10-0800200c9a66";
  static const String ROLL_UUID = "e659f308-ea98-11e3-ac10-0800200c9a66";
  static const String YAW_UUID = "e659f309-ea98-11e3-ac10-0800200c9a66";
  static const String TRIP_ODOMETER_UUID = "e659f30a-ea98-11e3-ac10-0800200c9a66";
  static const String RPM_UUID = "e659f30b-ea98-11e3-ac10-0800200c9a66";
  static const String TEMPERATURE_UUID = "e659f310-ea98-11e3-ac10-0800200c9a66";
  static const String FIRMWARE_REVISION_UUID = "e659f311-ea98-11e3-ac10-0800200c9a66";
  static const String CURRENT_AMPS_UUID = "e659f312-ea98-11e3-ac10-0800200c9a66";
  static const String BATTERY_VOLTAGE_UUID = "e659f316-ea98-11e3-ac10-0800200c9a66";
  static const String LIFETIME_ODOMETER_UUID = "e659f319-ea98-11e3-ac10-0800200c9a66";
  static const String UART_SERIAL_READ_UUID = "e659f3fe-ea98-11e3-ac10-0800200c9a66";
  static const String UART_SERIAL_WRITE_UUID = "e659f3ff-ea98-11e3-ac10-0800200c9a66";
  
  // Enhanced device discovery with better filtering
  static const List<String> KNOWN_ONEWHEEL_NAMES = [
    'onewheel', 'ow', 'future motion', 'fm', 'pint', 'xr', 'gt', 'onewheel+'
  ];
  
  // Known OneWheel MAC address prefixes (OUI ranges)
  static const List<String> KNOWN_OUI_PREFIXES = [
    '00:13:43', // Future Motion OUI
    '00:1B:63', // Common OneWheel range
  ];
  
  // Connection state management
  enum ConnectionState {
    disconnected,
    scanning,
    connecting,
    connected,
    authenticating,
    authenticated,
    error
  }
  
  BluetoothDevice? _connectedDevice;
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _lastError;
  
  // Enhanced characteristic management
  final Map<String, BluetoothCharacteristic> _characteristics = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  
  // Improved data streaming
  final StreamController<OnewheelData> _dataController = StreamController<OnewheelData>.broadcast();
  Stream<OnewheelData> get dataStream => _dataController.stream;
  
  OnewheelData _currentData = OnewheelData();
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
  ConnectionState get connectionState => _connectionState;
  String? get lastError => _lastError;
  bool get isConnected => _connectionState == ConnectionState.connected || 
                         _connectionState == ConnectionState.authenticated;
  bool get isUnlocked => _connectionState == ConnectionState.authenticated;
  bool get isScanning => _connectionState == ConnectionState.scanning;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;
  /// Enhanced device discovery with better filtering
  Future<void> startScan() async {
    if (_connectionState == ConnectionState.scanning) return;
    
    _updateConnectionState(ConnectionState.scanning);
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
        withServices: [Guid(SERVICE_UUID)],
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
    await FlutterBluePlus.stopScan();
    if (_connectionState == ConnectionState.scanning) {
      _updateConnectionState(ConnectionState.disconnected);
    }
  }

  /// Enhanced OneWheel device detection
  bool isEnhancedOnewheelDevice(ScanResult scanResult) {
    final device = scanResult.device;
    final name = device.platformName.toLowerCase();
    
    // Check device name patterns
    bool nameMatch = KNOWN_ONEWHEEL_NAMES.any((pattern) => 
        name.contains(pattern) || name.startsWith(pattern.substring(0, 2)));
    
    // Check MAC address OUI if available
    bool ouiMatch = false;
    try {
      final macAddress = device.remoteId.str.toUpperCase();
      ouiMatch = KNOWN_OUI_PREFIXES.any((oui) => 
          macAddress.startsWith(oui.replaceAll(':', '')));
    } catch (e) {
      // MAC address not available or parseable
    }
    
    // Check advertised services
    bool serviceMatch = scanResult.advertisementData.serviceUuids
        .any((uuid) => uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase());
    
    // Check signal strength (avoid very weak signals)
    bool signalStrengthOk = scanResult.rssi > -80;
    
    // Device is likely OneWheel if name matches or (OUI + service) match
    return (nameMatch || (ouiMatch && serviceMatch)) && signalStrengthOk;
  }

  /// Legacy device detection method for backward compatibility
  static bool isOnewheelDevice(BluetoothDevice device, List<String>? advertisedServiceUuids) {
    final name = device.platformName.toLowerCase();
    
    // Check device name patterns
    final namePatterns = ['onewheel', 'ow', 'future motion', 'fm', 'pint', 'xr', 'gt'];
    bool nameMatch = namePatterns.any((pattern) => name.contains(pattern));
    
    // Check advertised service UUIDs if available
    bool serviceMatch = false;
    if (advertisedServiceUuids != null) {
      serviceMatch = advertisedServiceUuids.any((uuid) => 
          uuid.toLowerCase() == SERVICE_UUID.toLowerCase());
    }
    
    return nameMatch || serviceMatch;
  }

  /// Enhanced connection with better state management
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_connectionState == ConnectionState.connecting || 
        _connectionState == ConnectionState.connected) {
      return;
    }
    
    _updateConnectionState(ConnectionState.connecting);
    
    try {
      print('Connecting to ${device.platformName} (${device.remoteId})...');
      
      // Enhanced connection with retry logic
      await _connectWithRetry(device);
      _connectedDevice = device;
      _updateConnectionState(ConnectionState.connected);
      
      // Start connection watchdog
      _startConnectionWatchdog();
      
      // Discover services with timeout
      await _discoverServicesWithTimeout(device);
      
      // Perform enhanced authentication
      await _performEnhancedAuthentication();
      
      // Subscribe to characteristics
      await _subscribeToCharacteristics();
      
      _updateConnectionState(ConnectionState.authenticated);
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
      if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
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
      
      print('Connected to ${device.platformName}');
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      print('Discovered ${services.length} services');
      
      // Find the main OneWheel service
      BluetoothService? owService;
      for (BluetoothService service in services) {
        print('Found service: ${service.uuid}');
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          owService = service;
          break;
        }
      }
      
      if (owService == null) {
        print('OneWheel service not found. Available services:');
        for (BluetoothService service in services) {
          print('  - ${service.uuid}');
        }
        throw Exception('OneWheel service not found. This may not be a OneWheel device.');
      }
      
      print('Found OneWheel service with ${owService.characteristics.length} characteristics');
      
      // Get characteristics
      for (BluetoothCharacteristic characteristic in owService.characteristics) {
        String uuid = characteristic.uuid.toString().toLowerCase();
        
        switch (uuid) {
          case FIRMWARE_REVISION_UUID:
            _firmwareRevisionChar = characteristic;
            break;
          case UART_SERIAL_READ_UUID:
            _uartReadChar = characteristic;
            break;
          case UART_SERIAL_WRITE_UUID:
            _uartWriteChar = characteristic;
            break;
        }
      }
      
      // Perform unlock handshake
      await _performUnlockHandshake();
      
      // Start data subscription
      await _subscribeToDataCharacteristics(owService);
      
    } catch (e) {
      print('Error connecting to device: $e');
      await disconnect();
      rethrow;
    }
  }

  /// Perform the OneWheel unlock handshake
  Future<void> _performUnlockHandshake() async {
    if (_firmwareRevisionChar == null || _uartReadChar == null || _uartWriteChar == null) {
      throw Exception('Required characteristics not found for handshake');
    }
    
    try {
      print('Starting OneWheel unlock handshake...');
      
      // Read firmware revision
      List<int> firmwareData = await _firmwareRevisionChar!.read();
      print('Firmware revision: ${firmwareData}');
      
      // Subscribe to UART read for challenge
      await _uartReadChar!.setNotifyValue(true);
      
      List<int> challenge = [];
      Completer<void> challengeCompleter = Completer<void>();
      
      // Listen for challenge data
      StreamSubscription? challengeSub;
      challengeSub = _uartReadChar!.onValueReceived.listen((data) {
        challenge.addAll(data);
        print('Challenge data received: ${data.length} bytes, total: ${challenge.length}');
        
        if (challenge.length >= 20) {
          challengeSub?.cancel();
          challengeCompleter.complete();
        }
      });
      
      // Initiate handshake by writing firmware revision back
      await _firmwareRevisionChar!.write(firmwareData, withoutResponse: false);
      
      // Wait for challenge
      await challengeCompleter.future.timeout(const Duration(seconds: 10));
      
      // Unsubscribe from UART read
      await _uartReadChar!.setNotifyValue(false);
      
      // Verify challenge signature
      if (challenge.length < 3 || 
          challenge[0] != 0x43 || 
          challenge[1] != 0x52 || 
          challenge[2] != 0x58) {
        throw Exception('Invalid challenge signature');
      }
      
      // Prepare response
      List<int> response = await _generateChallengeResponse(challenge);
      
      // Send response
      await _uartWriteChar!.write(response, withoutResponse: false);
      
      _isUnlocked = true;
      notifyListeners();
      
      print('OneWheel unlocked successfully!');
      
      // Schedule periodic unlock renewal (every 20 seconds)
      _unlockTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
        try {
          await _firmwareRevisionChar!.write(firmwareData, withoutResponse: false);
          print('Unlock renewed');
        } catch (e) {
          print('Failed to renew unlock: $e');
        }
      });
      
    } catch (e) {
      print('Handshake failed: $e');
      rethrow;
    }
  }

  /// Generate challenge response using MD5 hash
  Future<List<int>> _generateChallengeResponse(List<int> challenge) async {
    // Known OneWheel password from reverse engineering
    List<int> password = [0xd9, 0x25, 0x5f, 0x0f, 0x23, 0x35, 0x4e, 0x19, 
                         0xba, 0x73, 0x9c, 0xcd, 0xc4, 0xa9, 0x17, 0x65];
    
    // Prepare data for MD5: challenge[3:-1] + password
    List<int> md5Input = [];
    md5Input.addAll(challenge.sublist(3, challenge.length - 1));
    md5Input.addAll(password);
    
    // Calculate MD5 using proper crypto library
    var digest = md5.convert(md5Input);
    List<int> md5Hash = digest.bytes;
    
    // Build response: signature + md5Hash
    List<int> response = [];
    response.addAll([0x43, 0x52, 0x58]); // Signature
    response.addAll(md5Hash);
    
    // Calculate check byte
    int checkByte = 0;
    for (int byte in response) {
      checkByte ^= byte;
    }
    response.add(checkByte);
    
    return response;
  }

  /// Enhanced authentication with better error handling
  Future<void> _performEnhancedAuthentication() async {
    _updateConnectionState(ConnectionState.authenticating);
    
    final firmwareChar = _characteristics[FIRMWARE_REVISION_UUID.toLowerCase()];
    final uartReadChar = _characteristics[UART_SERIAL_READ_UUID.toLowerCase()];
    final uartWriteChar = _characteristics[UART_SERIAL_WRITE_UUID.toLowerCase()];
    
    if (firmwareChar == null || uartReadChar == null || uartWriteChar == null) {
      throw Exception('Required characteristics not found for authentication');
    }
    
    try {
      print('Starting enhanced OneWheel authentication...');
      
      // Read firmware with retry
      List<int> firmwareData = await _readCharacteristicWithRetry(firmwareChar);
      print('Firmware version: ${firmwareData}');
      
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
      await _validateAndRespondToChallenge(challenge, uartWriteChar);
      
    } finally {
      await challengeSub.cancel();
    }
  }
  
  /// Enhanced challenge validation and response
  Future<void> _validateAndRespondToChallenge(List<int> challenge, BluetoothCharacteristic uartWriteChar) async {
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
    
    // Start adaptive data collection
    _startDataCollection();
  }
  
  /// Enhanced characteristic data handling
  void _handleCharacteristicData(String uuid, List<int> data) {
    if (data.isEmpty) return;
    
    try {
      // Process data based on characteristic UUID
      switch (uuid.toLowerCase()) {
        case BATTERY_PERCENT_UUID:
          if (data.isNotEmpty) {
            _currentData.batteryPercent = data[0].toDouble();
          }
          break;
        case PITCH_UUID:
          if (data.length >= 2) {
            final pitchRaw = (data[1] << 8) | data[0];
            _currentData.pitch = pitchRaw / 100.0;
          }
          break;
        case ROLL_UUID:
          if (data.length >= 2) {
            final rollRaw = (data[1] << 8) | data[0];
            _currentData.roll = rollRaw / 100.0;
          }
          break;
        case YAW_UUID:
          if (data.length >= 2) {
            final yawRaw = (data[1] << 8) | data[0];
            _currentData.yaw = yawRaw / 100.0;
          }
          break;
        case RPM_UUID:
          if (data.length >= 2) {
            final rpmRaw = (data[1] << 8) | data[0];
            _currentData.rpm = rpmRaw.toDouble();
          }
          break;
        case TEMPERATURE_UUID:
          if (data.length >= 2) {
            final tempRaw = (data[1] << 8) | data[0];
            _currentData.motorTemperature = tempRaw / 100.0;
          }
          break;
        case CURRENT_AMPS_UUID:
          if (data.length >= 2) {
            final currentRaw = (data[1] << 8) | data[0];
            _currentData.currentAmps = currentRaw / 100.0;
          }
          break;
        case BATTERY_VOLTAGE_UUID:
          if (data.length >= 2) {
            final voltageRaw = (data[1] << 8) | data[0];
            _currentData.batteryVoltage = voltageRaw / 100.0;
          }
          break;
        case TRIP_ODOMETER_UUID:
          if (data.length >= 4) {
            final tripRaw = (data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0];
            _currentData.tripOdometer = tripRaw / 1000.0;
          }
          break;
        case LIFETIME_ODOMETER_UUID:
          if (data.length >= 4) {
            final lifetimeRaw = (data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0];
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
  
  /// Start adaptive data collection
  void _startDataCollection() {
    // Use a more efficient adaptive sampling rate
    _dataTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (_connectionState == ConnectionState.authenticated) {
        // Data is collected through characteristic notifications
        // This timer is just for periodic updates and validation
        notifyListeners();
      }
    });
  }
  
  /// Enhanced error handling
  void _handleError(String error) {
    _lastError = error;
    _updateConnectionState(ConnectionState.error);
    print('Error: $error');
  }
  
  /// Update connection state with notification
  void _updateConnectionState(ConnectionState newState) {
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
    _updateConnectionState(ConnectionState.disconnected);
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
      final adapterState = await FlutterBluePlus.adapterState.first;
      info['bluetoothOn'] = adapterState == BluetoothAdapterState.on;
      
      // Connection state
      info['connectionState'] = _connectionState.toString();
      info['lastError'] = _lastError;
      info['connectedDevice'] = _connectedDevice?.platformName ?? 'None';
      info['connectedDeviceId'] = _connectedDevice?.remoteId.str ?? 'None';
      
      // Scan results
      final devices = getAvailableOnewheelDevices();
      info['onewheelDevicesFound'] = devices.length;
      info['onewheelDeviceNames'] = devices.map((d) => d.platformName).where((name) => name.isNotEmpty).toList();
      
      // All scan results for debugging
      final allScanResults = await FlutterBluePlus.scanResults.first;
      info['totalDevicesFound'] = allScanResults.length;
      info['allDeviceNames'] = allScanResults.map((r) => r.device.platformName).where((name) => name.isNotEmpty).take(20).toList();
      
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
}

/// OneWheel data model
class OnewheelData {
  double speed = 0.0; // km/h
  double rpm = 0.0;
  double batteryPercent = 0.0;
  double batteryVoltage = 0.0;
  double motorTemperature = 0.0;
  double controllerTemperature = 0.0;
  double currentAmps = 0.0;
  double pitch = 0.0;
  double roll = 0.0;
  double yaw = 0.0;
  double tripOdometer = 0.0; // km
  double lifetimeOdometer = 0.0; // km
  double tripDistance = 0.0; // km - legacy property
  double lifetimeDistance = 0.0; // km - legacy property
  String rideMode = 'Unknown';
  bool isCharging = false;
  bool isRiding = false;
  DateTime timestamp = DateTime.now();
  
  OnewheelData();
  
  Map<String, dynamic> toJson() {
    return {
      'speed': speed,
      'rpm': rpm,
      'batteryPercent': batteryPercent,
      'batteryVoltage': batteryVoltage,
      'motorTemperature': motorTemperature,
      'controllerTemperature': controllerTemperature,
      'currentAmps': currentAmps,
      'pitch': pitch,
      'roll': roll,
      'yaw': yaw,
      'tripOdometer': tripOdometer,
      'lifetimeOdometer': lifetimeOdometer,
      'tripDistance': tripDistance,
      'lifetimeDistance': lifetimeDistance,
      'rideMode': rideMode,
      'isCharging': isCharging,
      'isRiding': isRiding,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
