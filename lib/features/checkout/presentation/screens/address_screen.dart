/// Collects the delivery address used during checkout.
library;
import 'package:flutter/material.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key, this.initialAddress});

  final String? initialAddress;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  static const List<_DeliveryAddress> _addresses = [
    _DeliveryAddress(city: 'Addis Ababa', details: 'Bole, Addis Ababa, Ethiopia'),
    _DeliveryAddress(city: 'Addis Ababa', details: 'Piassa, Addis Ababa, Ethiopia'),
    _DeliveryAddress(city: 'Addis Ababa', details: 'CMC, Addis Ababa, Ethiopia'),
  ];

  late int _selectedIndex;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _addressController = TextEditingController(
      text: widget.initialAddress?.trim().isNotEmpty == true ? widget.initialAddress!.trim() : _addresses.first.details,
    );
    _addressController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Address')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose your location', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              const Text(
                'Select a location below so delivery can get started.',
                style: TextStyle(color: Color(0xFF8D92A3)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCCD2E0)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: Color(0xFF6E63FF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Addis Ababa',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.gps_fixed_rounded, color: Color(0xFF8D92A3)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('address.manual-field'),
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Enter full address',
                  hintText: 'House number, area, kebele, nearby landmark',
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Select location', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    final isSelected = index == _selectedIndex;
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                          _addressController.text = address.details;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6E63FF) : const Color(0xFFE5E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(address.city, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(address.details, style: const TextStyle(color: Color(0xFF8D92A3))),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isSelected ? const Color(0xFF6E63FF) : const Color(0xFFEFF1F7),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: isSelected ? Colors.white : const Color(0xFF8D92A3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _addressController.text.trim().isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pop(_addressController.text.trim());
                      },
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryAddress {
  const _DeliveryAddress({required this.city, required this.details});

  final String city;
  final String details;
}
