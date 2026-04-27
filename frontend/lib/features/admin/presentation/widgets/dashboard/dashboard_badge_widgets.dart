import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/services/admin_dashboard_formatters.dart';

class DashboardActionIconButton extends StatelessWidget {
  const DashboardActionIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.badgeCount,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final int badgeCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: DashboardIconWithBadge(icon: icon, badgeCount: badgeCount),
    );
  }
}

class DashboardIconWithBadge extends StatelessWidget {
  const DashboardIconWithBadge({
    super.key,
    required this.icon,
    required this.badgeCount,
  });

  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (badgeCount > 0)
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                formatDashboardBadgeCount(badgeCount),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
