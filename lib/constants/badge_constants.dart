import '../models/badge.dart';

class BadgeConstants {
  static final List<BadgeTemplate> allPossibleBadges = [
    BadgeTemplate(
      type: 'distance',
      name: 'First Mile',
      description: 'Complete your first ride',
      icon: '🎯',
    ),
    BadgeTemplate(
      type: 'distance',
      name: 'Ten Miles',
      description: 'Ride 10 miles total',
      icon: '🏃',
    ),
    BadgeTemplate(
      type: 'distance',
      name: 'Century Rider',
      description: 'Ride 100 miles total',
      icon: '🏆',
    ),
    BadgeTemplate(
      type: 'efficiency',
      name: 'Eco Master',
      description: 'Achieve 90%+ battery efficiency',
      icon: '🔋',
    ),
    BadgeTemplate(
      type: 'safety',
      name: 'Safe Rider',
      description: 'Complete 10 rides safely',
      icon: '🛡️',
    ),
    BadgeTemplate(
      type: 'speed',
      name: 'Speed Demon',
      description: 'Hit 20+ mph in a ride',
      icon: '🚀',
    ),
    BadgeTemplate(
      type: 'consistency',
      name: 'Steady Eddy',
      description: 'Maintain consistent speed',
      icon: '⚖️',
    ),
    BadgeTemplate(
      type: 'endurance',
      name: 'Marathon Rider',
      description: 'Ride for 2+ hours straight',
      icon: '⏰',
    ),
    BadgeTemplate(
      type: 'explorer',
      name: 'Trail Blazer',
      description: 'Explore 5 different routes',
      icon: '🗺️',
    ),
    BadgeTemplate(
      type: 'night',
      name: 'Night Owl',
      description: 'Complete a night ride',
      icon: '🌙',
    ),
  ];

  static BadgeTemplate? getBadgeTemplate(String name) {
    try {
      return allPossibleBadges.firstWhere((badge) => badge.name == name);
    } catch (e) {
      return null;
    }
  }
}

class BadgeTemplate {
  final String type;
  final String name;
  final String description;
  final String icon;

  BadgeTemplate({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
  });

  Badge toEarnedBadge(DateTime earnedAt) {
    return Badge(
      id: type, // Use type as id for consistency
      type: type,
      name: name,
      description: description,
      isEarned: true,
      earnedDate: earnedAt,
    );
  }
}
