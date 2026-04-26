/// Dedicated admin page for payment option management.
library;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

class AdminPaymentOptionsScreen extends StatefulWidget {
  const AdminPaymentOptionsScreen({
    super.key,
    required this.paymentOptions,
    this.onAddPaymentOption,
    this.onFetchPaymentOption,
    this.onUpdatePaymentOption,
    this.onDeletePaymentOption,
    this.onTogglePaymentOption,
  });

  final List<PaymentOption> paymentOptions;
  final Future<void> Function({required String label, String? iconUrl})? onAddPaymentOption;
  final Future<PaymentOption?> Function(String optionId)? onFetchPaymentOption;
  final Future<void> Function({required String optionId, required String label, String? iconUrl})? onUpdatePaymentOption;
  final Future<void> Function(String optionId)? onDeletePaymentOption;
  final Future<void> Function(String optionId, bool isEnabled)? onTogglePaymentOption;

  @override
  State<AdminPaymentOptionsScreen> createState() => _AdminPaymentOptionsScreenState();
}

class _AdminPaymentOptionsScreenState extends State<AdminPaymentOptionsScreen> {
  // Local list is used for immediate UI updates after mutations.
  late List<PaymentOption> _options;

  @override
  void initState() {
    super.initState();
    // Seed state from parent-provided options.
    _options = List<PaymentOption>.from(widget.paymentOptions);
  }

  Future<void> _showPaymentDialog({PaymentOption? option, required bool isNew}) async {
    // Shared add/edit dialog keeps validation and field layout consistent.
    final labelController = TextEditingController(text: option?.label ?? '');
    final iconController = TextEditingController(text: option?.iconUrl ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isNew ? 'Add Payment Method' : 'Edit Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: iconController, decoration: const InputDecoration(labelText: 'Icon URL (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final label = labelController.text.trim();
              if (label.isEmpty) {
                return;
              }
              if (isNew) {
                await widget.onAddPaymentOption?.call(label: label, iconUrl: iconController.text.trim());
              } else {
                await widget.onUpdatePaymentOption?.call(
                  optionId: option!.id,
                  label: label,
                  iconUrl: iconController.text.trim(),
                );
              }

              if (!mounted) {
                return;
              }

              setState(() {
                if (isNew) {
                  // Insert new option at top so admins can confirm result instantly.
                  _options = [
                    PaymentOption(
                      id: _slugify(label),
                      method: PaymentMethod.fromRaw(_slugify(label), label: label),
                      label: label,
                      isEnabled: true,
                      iconUrl: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                    ),
                    ..._options,
                  ];
                } else {
                  // Update edited item in place to avoid rebuilding unrelated rows.
                  final index = _options.indexWhere((item) => item.id == option!.id);
                  if (index != -1) {
                    _options[index] = _options[index].copyWith(
                      label: label,
                      iconUrl: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                    );
                  }
                }
              });
              Navigator.of(dialogContext).pop();
            },
            child: Text(isNew ? 'Save' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(PaymentOption option) async {
    // Confirmation prevents accidental removal of payment methods.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Delete ${option.label}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              await widget.onDeletePaymentOption?.call(option.id);
              if (!mounted) {
                return;
              }
              setState(() {
                _options.removeWhere((item) => item.id == option.id);
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
    // Quick metric for status banner.
    final enabledCount = _options.where((option) => option.isEnabled).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Options'),
        actions: [
          IconButton(
            tooltip: 'Add Payment',
            onPressed: widget.onAddPaymentOption == null ? null : () => _showPaymentDialog(isNew: true),
            icon: const Icon(Icons.add_card_outlined),
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
                  const Icon(Icons.payments_outlined, color: Color(0xFF1D4ED8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _options.isEmpty
                          ? 'No payment options found.'
                          : '$enabledCount of ${_options.length} payment option(s) enabled.',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _options.isEmpty
                ? const Center(child: Text('No payment options found.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = _options[index];
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
                            Text(option.label, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text('Method: ${option.method.label}'),
                            Text('Status: ${option.isEnabled ? 'enabled' : 'disabled'}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF5E56E7),
                                    ),
                                  ),
                                ),
                                Chip(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  label: Text(option.isEnabled ? 'enabled' : 'disabled', style: const TextStyle(color: Color(0xFF374151))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (widget.onTogglePaymentOption != null)
                                  OutlinedButton(
                                    onPressed: () async {
                                      // Toggle backend first, then mirror result in local list.
                                      final value = !option.isEnabled;
                                      await widget.onTogglePaymentOption?.call(option.id, value);
                                      if (!mounted) {
                                        return;
                                      }
                                      setState(() {
                                        _options[index] = _options[index].copyWith(isEnabled: value);
                                      });
                                    },
                                    child: Text(option.isEnabled ? 'Disable' : 'Enable'),
                                  ),
                                if (widget.onUpdatePaymentOption != null)
                                  OutlinedButton(
                                    onPressed: () async {
                                      final latest = await widget.onFetchPaymentOption?.call(option.id);
                                      if (!mounted) {
                                        return;
                                      }
                                      await _showPaymentDialog(option: latest ?? option, isNew: false);
                                    },
                                    child: const Text('Edit'),
                                  ),
                                if (widget.onDeletePaymentOption != null)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                                    onPressed: () => _showDeleteDialog(option),
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
    // Stable id generation for locally inserted options before server roundtrip.
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
