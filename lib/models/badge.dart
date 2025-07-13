class Badge {
  final String id;
  final String type;
  final String name;
  final String description;
  final bool isEarned;
  final DateTime? earnedDate;

  Badge({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.isEarned,
    this.earnedDate,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? '',
      type: json['badge_type'] ?? json['type'] ?? '',
      name: json['badge_name'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      isEarned: json['is_earned'] ?? json['isEarned'] ?? false,
      earnedDate: json['earned_at'] != null 
          ? DateTime.parse(json['earned_at'])
          : (json['earnedDate'] != null ? DateTime.parse(json['earnedDate']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'description': description,
      'isEarned': isEarned,
      'earnedDate': earnedDate?.toIso8601String(),
    };
  }
}
