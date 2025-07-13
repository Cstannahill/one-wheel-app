import 'package:flutter/foundation.dart';

/// User profile model with optional personal information
/// Uses device UUID as primary identifier for privacy-first approach
class UserProfile {
  final String deviceId; // Device UUID - primary identifier
  final String? name; // Optional display name
  final String? email; // Optional email for notifications/backup
  final String? phone; // Optional phone for SMS notifications
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> preferences;

  const UserProfile({
    required this.deviceId,
    this.name,
    this.email,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.preferences = const {},
  });

  /// Create a new user profile with device ID
  factory UserProfile.create({
    required String deviceId,
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? preferences,
  }) {
    final now = DateTime.now();
    return UserProfile(
      deviceId: deviceId,
      name: name,
      email: email,
      phone: phone,
      createdAt: now,
      updatedAt: now,
      preferences: preferences ?? {},
    );
  }

  /// Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      deviceId: json['deviceId'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? deviceId,
    String? name,
    String? email,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      preferences: preferences ?? this.preferences,
    );
  }

  /// Check if user has complete profile
  bool get hasCompleteProfile {
    return name != null && name!.isNotEmpty &&
           email != null && email!.isNotEmpty;
  }

  /// Check if user has notification preferences
  bool get canReceiveNotifications {
    return email != null || phone != null;
  }

  /// Get display name (fallback to "OneWheel Rider" if no name set)
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    return 'OneWheel Rider';
  }

  /// Get initials for avatar display
  String get initials {
    if (name == null || name!.isEmpty) {
      return 'OR'; // OneWheel Rider
    }
    
    final parts = name!.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;

  @override
  String toString() {
    return 'UserProfile(deviceId: $deviceId, name: $name, email: $email, hasPhone: ${phone != null})';
  }
}
