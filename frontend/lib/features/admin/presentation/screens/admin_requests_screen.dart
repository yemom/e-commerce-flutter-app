/// Dedicated admin page for admin account requests and approvals.
library;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({
    super.key,
    required this.adminAccounts,
    this.onCreateAdminAccount,
    this.onFetchAdminAccount,
    this.onUpdateAdminAccount,
    this.onApproveAdmin,
    this.onRemoveAdmin,
  });

  final List<AdminAccount> adminAccounts;
  final Future<void> Function({required String name, required String email, required String password})? onCreateAdminAccount;
  final Future<AdminAccount?> Function(String userId)? onFetchAdminAccount;
  final Future<void> Function({required String userId, required String name, required String email})? onUpdateAdminAccount;
  final Future<void> Function({required String userId, required bool approved})? onApproveAdmin;
  final Future<void> Function(String userId)? onRemoveAdmin;

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  // Local mutable copy so UI updates instantly after each admin action.
  late List<AdminAccount> _accounts;

  @override
  void initState() {
    super.initState();
    // Snapshot current provider data into local state for fast optimistic updates.
    _accounts = List<AdminAccount>.from(widget.adminAccounts);
  }

  Future<void> _showCreateAdminDialog() async {
    // Collect required identity + password fields for a new admin account.
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var obscurePassword = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          title: const Text('Create Admin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Admin name')),
                const SizedBox(height: 10),
                TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Admin email')),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Admin password',
                    suffixIcon: IconButton(
                      onPressed: () => setStateDialog(() => obscurePassword = !obscurePassword),
                      icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await widget.onCreateAdminAccount?.call(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  password: passwordController.text,
                );
                if (!mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditAdminDialog(AdminAccount admin) async {
    // Edit only mutable profile fields for existing admin records.
    final nameController = TextEditingController(text: admin.name);
    final emailController = TextEditingController(text: admin.email);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Admin name')),
            const SizedBox(height: 10),
            TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Admin email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await widget.onUpdateAdminAccount?.call(
                userId: admin.userId,
                name: nameController.text.trim(),
                email: emailController.text.trim(),
              );
              if (!mounted) {
                return;
              }
              setState(() {
                // Keep local list in sync so user sees change without leaving page.
                final index = _accounts.indexWhere((item) => item.userId == admin.userId);
                if (index != -1) {
                  _accounts[index] = AdminAccount(
                    userId: admin.userId,
                    role: admin.role,
                    approved: admin.approved,
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                  );
                }
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAdminDialog(AdminAccount admin) async {
    // Confirm destructive action to avoid accidental removal.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text('Delete ${admin.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              await widget.onRemoveAdmin?.call(admin.userId);
              if (!mounted) {
                return;
              }
              setState(() {
                _accounts.removeWhere((item) => item.userId == admin.userId);
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showApproveAdminDialog(AdminAccount admin) async {
    // Toggle between pending/approved state for request moderation.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Admin'),
        content: Text('${admin.approved ? 'Mark' : 'Approve'} ${admin.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await widget.onApproveAdmin?.call(userId: admin.userId, approved: !admin.approved);
              if (!mounted) {
                return;
              }
              setState(() {
                // Replace one item in-place to preserve list scroll position.
                final index = _accounts.indexWhere((item) => item.userId == admin.userId);
                if (index != -1) {
                  final current = _accounts[index];
                  _accounts[index] = AdminAccount(
                    userId: current.userId,
                    email: current.email,
                    name: current.name,
                    role: current.role,
                    approved: !current.approved,
                  );
                }
              });
              Navigator.of(dialogContext).pop();
            },
            child: Text(admin.approved ? 'Set pending' : 'Approve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Grouping lets us show request queue first, then active/super admins.
    final pendingRequests = _accounts.where((admin) => admin.role == AppUserRole.admin && !admin.approved).toList();
    final activeAdmins = _accounts.where((admin) => admin.role == AppUserRole.admin && admin.approved).toList();
    final superAdmins = _accounts.where((admin) => admin.role == AppUserRole.superAdmin).toList();
    final adminItems = [...pendingRequests, ...activeAdmins, ...superAdmins];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Requests'),
        actions: [
          IconButton(
            tooltip: 'Create Admin',
            onPressed: widget.onCreateAdminAccount == null ? null : _showCreateAdminDialog,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFD2AE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.manage_accounts_outlined, color: Color(0xFFB45309)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pendingRequests.isEmpty
                          ? 'No pending admin requests right now.'
                          : '${pendingRequests.length} pending admin request(s) need review.',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF9A3412)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: adminItems.isEmpty
                ? const Center(child: Text('No admin accounts found.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: adminItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final admin = adminItems[index];
                      final isPending = admin.role == AppUserRole.admin && !admin.approved;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE7ECF3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(admin.name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text(admin.email),
                            const SizedBox(height: 6),
                            Text('Role: ${admin.role.value}'),
                            Text('Status: ${admin.approved ? 'approved' : 'pending'}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isPending ? 'Review this request' : 'Admin account',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF5E56E7),
                                    ),
                                  ),
                                ),
                                Chip(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  label: Text(admin.approved ? 'approved' : 'pending', style: const TextStyle(color: Color(0xFF374151))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (isPending && widget.onApproveAdmin != null)
                                  OutlinedButton(
                                    onPressed: () => _showApproveAdminDialog(admin),
                                    child: const Text('Approve'),
                                  ),
                                if (!isPending && widget.onUpdateAdminAccount != null)
                                  OutlinedButton(
                                    onPressed: () async {
                                      final latest = await widget.onFetchAdminAccount?.call(admin.userId);
                                      if (!mounted) {
                                        return;
                                      }
                                      await _showEditAdminDialog(latest ?? admin);
                                    },
                                    child: const Text('Edit'),
                                  ),
                                if (widget.onRemoveAdmin != null)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                                    onPressed: () => _showDeleteAdminDialog(admin),
                                    child: Text(isPending ? 'Delete request' : 'Delete'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
