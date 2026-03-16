/// Lets users choose which branch they want to shop from.
library;
import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';

class BranchSelectionScreen extends StatelessWidget {
  const BranchSelectionScreen({
    super.key,
    required this.branches,
    required this.selectedBranchId,
    required this.onSelected,
    required this.onContinue,
  });

  final List<Branch> branches;
  final String? selectedBranchId;
  final ValueChanged<String> onSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    // Branch selection controls downstream stock and delivery calculations.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5E56E7), Color(0xFF5E56E7), Color(0xFFF6F7FB)],
            stops: [0, .26, .26],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Choose your branch',
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select the market nearest to you for accurate stock and delivery.',
                  style: TextStyle(color: Color(0xFFDCDDFF)),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: ListView.separated(
                      itemCount: branches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        final isSelected = branch.id == selectedBranchId;
                        return ListTile(
                          onTap: () => onSelected(branch.id),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF5E56E7) : const Color(0xFFE7ECF3),
                            ),
                          ),
                          tileColor: isSelected ? const Color(0xFFF0EEFF) : Colors.white,
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF5E56E7) : const Color(0xFFF1F2F8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.storefront_outlined,
                              color: isSelected ? Colors.white : const Color(0xFF5E56E7),
                            ),
                          ),
                          title: Text(branch.name),
                          subtitle: Text(branch.location),
                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF5E56E7)) : null,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: selectedBranchId == null ? null : onContinue,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}