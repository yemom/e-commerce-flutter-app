import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/add_product_screen.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';

void main() {
  testWidgets('Image picker integration test', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AddProductScreen(
            categories: [
              Category(
                id: 'c1',
                name: 'Cat',
                description: 'Desc',
                imageUrl: 'url',
                isActive: true,
              ),
            ],
            branches: [
              Branch(
                id: 'b1',
                name: 'Branch',
                location: 'loc',
                phoneNumber: '123',
                isActive: true,
              ),
            ],
            onUploadImage: ({required bytes, required fileName}) async => 'url',
            onSubmit: (product) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final button = find.byKey(const Key('add-product.pick-image-button'));
    expect(button, findsOneWidget);

    // This will invoke _pickImageFromDevice
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  });
}
