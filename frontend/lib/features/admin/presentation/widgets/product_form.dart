import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/add_product_provider.dart';

class ProductForm extends ConsumerWidget {
  const ProductForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(addProductProvider.notifier);

    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: "Name"),
          onChanged: notifier.setName,
        ),
        TextField(
          decoration: const InputDecoration(labelText: "Description"),
          onChanged: notifier.setDescription,
        ),
        TextField(
          decoration: const InputDecoration(labelText: "Price"),
          keyboardType: TextInputType.number,
          onChanged: notifier.setPrice,
        ),
      ],
    );
  }
}
