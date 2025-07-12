class RideInsights {
  final String rideId;
  final double overallScore;
  final double speedEfficiency;
  final double energyEfficiency;
  final double routeQuality;
  final String rideStyle;
  final List<String> insights;
  final List<String> suggestions;
  final List<String> comparisons;
  final DateTime generatedAt;
  final String analysisType; // 'local' or 'ai'
  
  // AI-specific insights (when available)
  final Map<String, dynamic>? aiMetrics;
  final String? moodAnalysis;
  final List<String>? safetyTips;
  final Map<String, double>? skillProgression;

  const RideInsights({
    required this.rideId,
    required this.overallScore,
    required this.speedEfficiency,
    required this.energyEfficiency,
    required this.routeQuality,
    required this.rideStyle,
    required this.insights,
    required this.suggestions,
    required this.comparisons,
    required this.generatedAt,
    required this.analysisType,
    this.aiMetrics,
    this.moodAnalysis,
    this.safetyTips,
    this.skillProgression,
  });

  /// Create insights from server AI response
  factory RideInsights.fromServerResponse(Map<String, dynamic> data) {
    return RideInsights(
      rideId: data['rideId'] ?? '',
      overallScore: (data['overallScore'] ?? 0).toDouble(),
      speedEfficiency: (data['speedEfficiency'] ?? 0).toDouble(),
      energyEfficiency: (data['energyEfficiency'] ?? 0).toDouble(),
      routeQuality: (data['routeQuality'] ?? 0).toDouble(),
      rideStyle: data['rideStyle'] ?? 'Unknown',
      insights: List<String>.from(data['insights'] ?? []),
      suggestions: List<String>.from(data['suggestions'] ?? []),
      comparisons: List<String>.from(data['comparisons'] ?? []),
      generatedAt: DateTime.parse(data['generatedAt'] ?? DateTime.now().toIso8601String()),
      analysisType: 'ai',
      aiMetrics: data['aiMetrics'],
      moodAnalysis: data['moodAnalysis'],
      safetyTips: data['safetyTips'] != null ? List<String>.from(data['safetyTips']) : null,
      skillProgression: data['skillProgression'] != null 
          ? Map<String, double>.from(data['skillProgression']) 
          : null,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'overallScore': overallScore,
      'speedEfficiency': speedEfficiency,
      'energyEfficiency': energyEfficiency,
      'routeQuality': routeQuality,
      'rideStyle': rideStyle,
      'insights': insights,
      'suggestions': suggestions,
      'comparisons': comparisons,
      'generatedAt': generatedAt.toIso8601String(),
      'analysisType': analysisType,
      'aiMetrics': aiMetrics,
      'moodAnalysis': moodAnalysis,
      'safetyTips': safetyTips,
      'skillProgression': skillProgression,
    };
  }

  /// Create from stored JSON
  factory RideInsights.fromJson(Map<String, dynamic> json) {
    return RideInsights(
      rideId: json['rideId'] ?? '',
      overallScore: (json['overallScore'] ?? 0).toDouble(),
      speedEfficiency: (json['speedEfficiency'] ?? 0).toDouble(),
      energyEfficiency: (json['energyEfficiency'] ?? 0).toDouble(),
      routeQuality: (json['routeQuality'] ?? 0).toDouble(),
      rideStyle: json['rideStyle'] ?? 'Unknown',
      insights: List<String>.from(json['insights'] ?? []),
      suggestions: List<String>.from(json['suggestions'] ?? []),
      comparisons: List<String>.from(json['comparisons'] ?? []),
      generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
      analysisType: json['analysisType'] ?? 'local',
      aiMetrics: json['aiMetrics'],
      moodAnalysis: json['moodAnalysis'],
      safetyTips: json['safetyTips'] != null ? List<String>.from(json['safetyTips']) : null,
      skillProgression: json['skillProgression'] != null 
          ? Map<String, double>.from(json['skillProgression']) 
          : null,
    );
  }

  /// Get a color for the overall score
  int get scoreColor {
    if (overallScore >= 80) return 0xFF00FF88; // Green
    if (overallScore >= 60) return 0xFF00D4FF; // Blue
    if (overallScore >= 40) return 0xFFFFB74D; // Orange
    return 0xFFFF3366; // Red
  }

  /// Get an emoji for the ride style
  String get rideStyleEmoji {
    switch (rideStyle) {
      case 'Speed Demon': return '🚀';
      case 'Endurance Rider': return '🏃‍♂️';
      case 'Adrenaline Seeker': return '⚡';
      case 'Leisure Cruiser': return '🌅';
      case 'Balanced Rider': return '⚖️';
      default: return '🛹';
    }
  }

  /// Get efficiency grade
  String get efficiencyGrade {
    final avgEfficiency = (speedEfficiency + energyEfficiency) / 2;
    if (avgEfficiency >= 90) return 'A+';
    if (avgEfficiency >= 80) return 'A';
    if (avgEfficiency >= 70) return 'B';
    if (avgEfficiency >= 60) return 'C';
    return 'D';
  }

  /// Check if this is AI-powered analysis
  bool get isAIAnalysis => analysisType == 'ai';

  /// Get a summary sentence
  String get summary {
    return 'You\'re a ${rideStyle.toLowerCase()} with a ${efficiencyGrade} efficiency rating and ${overallScore.toStringAsFixed(0)}/100 performance score.';
  }
}
