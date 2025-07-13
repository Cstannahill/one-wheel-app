import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/badge.dart' as app_badge;
import '../providers/badge_provider.dart';

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, child) {
        if (badgeProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (badgeProvider.badges.isEmpty) {
          return const Center(
            child: Text(
              'No badges available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: badgeProvider.badges.length,
          itemBuilder: (context, index) {
            final badge = badgeProvider.badges[index];
            return _BadgeCard(badge: badge);
          },
        );
      },
    );
  }
}

class _BadgeCard extends StatefulWidget {
  final app_badge.Badge badge;

  const _BadgeCard({required this.badge});

  @override
  State<_BadgeCard> createState() => _BadgeCardState();
}

class _BadgeCardState extends State<_BadgeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _showBadgeDetails() {
    showDialog(
      context: context,
      builder: (context) => _BadgeDetailDialog(badge: widget.badge),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEarned = widget.badge.isEarned;
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _showBadgeDetails,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEarned
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.5),
                  width: isEarned ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isEarned
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : theme.colorScheme.onSurface.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getBadgeIcon(widget.badge.type),
                      size: 28,
                      color: isEarned
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Badge Name
                  Text(
                    widget.badge.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isEarned
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isEarned && widget.badge.earnedDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(widget.badge.earnedDate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getBadgeIcon(String type) {
    switch (type) {
      case 'first_ride':
        return Icons.directions_run;
      case 'distance_milestone':
        return Icons.straighten;
      case 'speed_demon':
        return Icons.speed;
      case 'explorer':
        return Icons.explore;
      case 'endurance':
        return Icons.timer;
      case 'consistency':
        return Icons.repeat;
      case 'early_bird':
        return Icons.wb_sunny;
      case 'night_rider':
        return Icons.nights_stay;
      case 'eco_warrior':
        return Icons.eco;
      case 'safety_first':
        return Icons.security;
      default:
        return Icons.stars;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }
}

class _BadgeDetailDialog extends StatelessWidget {
  final app_badge.Badge badge;

  const _BadgeDetailDialog({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEarned = badge.isEarned;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isEarned
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : theme.colorScheme.onSurface.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getBadgeIcon(badge.type),
                size: 40,
                color: isEarned
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),
            // Badge Name
            Text(
              badge.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isEarned
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Badge Description
            Text(
              badge.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (isEarned && badge.earnedDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Earned on ${_formatFullDate(badge.earnedDate!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBadgeIcon(String type) {
    switch (type) {
      case 'first_ride':
        return Icons.directions_run;
      case 'distance_milestone':
        return Icons.straighten;
      case 'speed_demon':
        return Icons.speed;
      case 'explorer':
        return Icons.explore;
      case 'endurance':
        return Icons.timer;
      case 'consistency':
        return Icons.repeat;
      case 'early_bird':
        return Icons.wb_sunny;
      case 'night_rider':
        return Icons.nights_stay;
      case 'eco_warrior':
        return Icons.eco;
      case 'safety_first':
        return Icons.security;
      default:
        return Icons.stars;
    }
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
