/// Dedicated admin page for branch management.
library;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';

class AdminBranchesScreen extends StatefulWidget {
  const AdminBranchesScreen({
    super.key,
    required this.branches,
    this.onFetchBranch,
    this.onUpdateBranch,
    this.onDeleteBranch,
  });

  final List<Branch> branches;
  final Future<Branch?> Function(String branchId)? onFetchBranch;
  final Future<void> Function({
    required String branchId,
    required String name,
    required String location,
    required String phoneNumber,
    required bool isActive,
  })? onUpdateBranch;
  final Future<void> Function(String branchId)? onDeleteBranch;

  @override
  State<AdminBranchesScreen> createState() => _AdminBranchesScreenState();
}

class _AdminBranchesScreenState extends State<AdminBranchesScreen> {
  late List<Branch> _branches;

  @override
  void initState() {
    super.initState();
    _branches = List<Branch>.from(widget.branches);
  }

  Future<void> _showBranchDialog({Branch? branch, required bool isNew}) async {
    final nameController = TextEditingController(text: branch?.name ?? '');
    final locationController = TextEditingController(text: branch?.location ?? '');
    final phoneController = TextEditingController(text: branch?.phoneNumber ?? '');
    var isActive = branch?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          title: Text(isNew ? 'Add Branch' : 'Edit Branch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Branch name')),
                const SizedBox(height: 10),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isActive,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active branch'),
                  onChanged: (value) => setStateDialog(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  return;
                }
                final branchId = branch?.id ?? _slugify(name);
                await widget.onUpdateBranch?.call(
                  branchId: branchId,
                  name: name,
                  location: locationController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  isActive: isActive,
                );
                if (!mounted) {
                  return;
                }
                setState(() {
                  final index = _branches.indexWhere((item) => item.id == branchId);
                  final updated = Branch(
                    id: branchId,
                    name: name,
                    location: locationController.text.trim(),
                    phoneNumber: phoneController.text.trim(),
                    isActive: isActive,
                  );
                  if (index == -1) {
                    _branches = [updated, ..._branches];
                  } else {
                    _branches[index] = updated;
                  }
                });
                Navigator.of(dialogContext).pop();
              },
              child: Text(isNew ? 'Save' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(Branch branch) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text('Delete ${branch.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              await widget.onDeleteBranch?.call(branch.id);
              if (!mounted) {
                return;
              }
              setState(() {
                _branches.removeWhere((item) => item.id == branch.id);
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Management'),
        actions: [
          IconButton(
            tooltip: 'Add Branch',
            onPressed: widget.onUpdateBranch == null ? null : () => _showBranchDialog(isNew: true),
            icon: const Icon(Icons.add_business_outlined),
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
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined, color: Color(0xFF1D4ED8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _branches.isEmpty
                          ? 'No branches found.'
                          : '${_branches.where((item) => item.isActive).length} of ${_branches.length} branch(es) active.',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _branches.isEmpty
                ? const Center(child: Text('No branches found.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _branches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final branch = _branches[index];
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
                            Text(branch.name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text('Location: ${branch.location}'),
                            Text('Phone: ${branch.phoneNumber}'),
                            Text('Status: ${branch.isActive ? 'active' : 'inactive'}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    branch.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF5E56E7),
                                    ),
                                  ),
                                ),
                                Chip(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  label: Text(
                                    branch.isActive ? 'active' : 'inactive',
                                    style: const TextStyle(color: Color(0xFF374151)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (widget.onUpdateBranch != null)
                                  OutlinedButton(
                                    onPressed: () async {
                                      final latest = await widget.onFetchBranch?.call(branch.id);
                                      if (!mounted) {
                                        return;
                                      }
                                      await _showBranchDialog(branch: latest ?? branch, isNew: false);
                                    },
                                    child: const Text('Edit'),
                                  ),
                                if (widget.onDeleteBranch != null)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                                    onPressed: () => _showDeleteDialog(branch),
                                    child: const Text('Delete'),
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

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
