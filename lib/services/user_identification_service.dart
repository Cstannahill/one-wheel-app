import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

/// Service for managing device-based user identification
/// Generates and maintains a unique device UUID for user identification
class UserIdentificationService {
  static const String _deviceIdKey = 'device_uuid';
  static const String _userProfileKey = 'user_profile';
  
  static UserIdentificationService? _instance;
  static UserIdentificationService get instance {
    _instance ??= UserIdentificationService._();
    return _instance!;
  }
  
  UserIdentificationService._();
  
  String? _deviceId;
  
  /// Get or generate device UUID
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we already have a stored device ID
    String? storedId = prefs.getString(_deviceIdKey);
    if (storedId != null && storedId.isNotEmpty) {
      _deviceId = storedId;
      return _deviceId!;
    }
    
    // Generate new device UUID
    _deviceId = await _generateDeviceUUID();
    await prefs.setString(_deviceIdKey, _deviceId!);
    
    print('📱 Generated new device UUID: $_deviceId');
    return _deviceId!;
  }
  
  /// Generate unique device UUID based on device characteristics
  Future<String> _generateDeviceUUID() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceSignature = '';
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceSignature = '${androidInfo.model}_${androidInfo.device}_${androidInfo.brand}_${androidInfo.manufacturer}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceSignature = '${iosInfo.model}_${iosInfo.systemName}_${iosInfo.systemVersion}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceSignature = '${linuxInfo.name}_${linuxInfo.version}_${linuxInfo.id}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceSignature = '${macInfo.model}_${macInfo.computerName}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceSignature = '${windowsInfo.computerName}_${windowsInfo.systemMemoryInMegabytes}';
      }
      
      // Add timestamp and random component for uniqueness
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(999999);
      final fullSignature = '${deviceSignature}_${timestamp}_$random';
      
      // Create SHA-256 hash and take first 32 characters for UUID-like format
      final bytes = utf8.encode(fullSignature);
      final hash = sha256.convert(bytes);
      final uuid = hash.toString().substring(0, 32);
      
      // Format as UUID: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
      return '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-${uuid.substring(12, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20, 32)}';
      
    } catch (e) {
      print('⚠️ Error generating device UUID: $e');
      // Fallback: generate random UUID
      return _generateFallbackUUID();
    }
  }
  
  /// Generate fallback UUID using random numbers
  String _generateFallbackUUID() {
    final random = Random();
    const chars = '0123456789abcdef';
    
    String uuid = '';
    for (int i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        uuid += '-';
      }
      uuid += chars[random.nextInt(chars.length)];
    }
    
    return uuid;
  }
  
  /// Clear device ID (for testing/reset purposes)
  Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_userProfileKey);
    _deviceId = null;
    print('🗑️ Device UUID cleared');
  }
  
  /// Get device information for display
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'Platform': 'Android',
          'Model': androidInfo.model,
          'Brand': androidInfo.brand,
          'Version': androidInfo.version.release,
          'Device ID': await getDeviceId(),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'Platform': 'iOS',
          'Model': iosInfo.model,
          'Name': iosInfo.name,
          'Version': iosInfo.systemVersion,
          'Device ID': await getDeviceId(),
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return {
          'Platform': 'Linux',
          'Name': linuxInfo.name,
          'Version': linuxInfo.version ?? 'Unknown',
          'Device ID': await getDeviceId(),
        };
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return {
          'Platform': 'macOS',
          'Model': macInfo.model,
          'Name': macInfo.computerName,
          'Device ID': await getDeviceId(),
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return {
          'Platform': 'Windows',
          'Name': windowsInfo.computerName,
          'Memory': '${windowsInfo.systemMemoryInMegabytes} MB',
          'Device ID': await getDeviceId(),
        };
      }
      
      return {
        'Platform': 'Unknown',
        'Device ID': await getDeviceId(),
      };
      
    } catch (e) {
      return {
        'Platform': 'Unknown',
        'Device ID': await getDeviceId(),
        'Error': e.toString(),
      };
    }
  }
}
