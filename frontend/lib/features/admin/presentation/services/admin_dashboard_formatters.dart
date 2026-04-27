String formatDashboardPercent(double share) {
  return '${(share * 100).toStringAsFixed(0)}%';
}

String formatDashboardBadgeCount(int count) {
  if (count > 99) {
    return '99+';
  }
  return '$count';
}
