import 'package:flutter/material.dart';

class AdminDashboardHeroCard extends StatelessWidget {
  const AdminDashboardHeroCard({
    super.key,
    required this.adminName,
    required this.dashboardTitle,
    required this.branchCount,
    required this.orderCount,
    required this.productCount,
    required this.categoryCount,
    required this.paymentCount,
    required this.pendingAdminCount,
    required this.activeAdminCount,
    required this.sectionTags,
  });

  final String? adminName;
  final String dashboardTitle;
  final int branchCount;
  final int orderCount;
  final int productCount;
  final int categoryCount;
  final int paymentCount;
  final int pendingAdminCount;
  final int activeAdminCount;
  final List<String> sectionTags;

 

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFC8400), Color(0xFFFF9A2E)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AFF8A00),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operations overview',
                      style: TextStyle(color: Color(0xFFFFF2E7), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    //display the current admin name in the hero card title if available, otherwise default to "Admin".
                    Text(
                      'Welcome, $adminName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Manage branches, requests, categories, payments, and products from one panel.',
                      style: TextStyle(
                        color: Color(0xFFFFF2E7),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Live control room',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(label: 'Branches', value: '$branchCount'),
              _HeroMetric(label: 'Orders', value: '$orderCount'),
              _HeroMetric(label: 'Products', value: '$productCount'),
              _HeroMetric(label: 'Categories', value: '$categoryCount'),
              _HeroMetric(label: 'Payments', value: '$paymentCount'),
              _HeroMetric(label: 'Pending admins', value: '$pendingAdminCount'),
              _HeroMetric(label: 'Active admins', value: '$activeAdminCount'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sectionTags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFFFF2E7), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
