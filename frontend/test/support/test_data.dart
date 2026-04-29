/// Test coverage for test_data behaviors.
library;

import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

final DateTime fixedDate = DateTime.utc(2026, 3, 13, 9, 30);

Branch buildBranch({
  String id = 'branch-addis-bole',
  String name = 'Addis Bole',
  String location = 'Bole Road, Addis Ababa',
  String phoneNumber = '+251911000001',
  bool isActive = true,
}) {
  return Branch(
    id: id,
    name: name,
    location: location,
    phoneNumber: phoneNumber,
    isActive: isActive,
  );
}

Category buildCategory({
  String id = 'cat-beverages',
  String name = 'Beverages',
  String description = 'Hot and cold drinks',
  String imageUrl = 'https://example.com/categories/beverages.png',
  bool isActive = true,
}) {
  return Category(
    id: id,
    name: name,
    description: description,
    imageUrl: imageUrl,
    isActive: isActive,
  );
}

Product buildProduct({
  String id = 'prod-coffee-1',
  String name = 'Arabica Coffee',
  String description = 'Single-origin Ethiopian coffee beans',
  String imageUrl = 'https://example.com/products/coffee.png',
  double price = 220,
  String categoryId = 'cat-beverages',
  List<String>? branchIds,
  Map<String, int>? stockByBranch,
  bool isAvailable = true,
  List<String>? availableSizes,
  List<ProductColorOption>? availableColors,
  List<String>? imageUrls,
  String? selectedSize,
  ProductColorOption? selectedColor,
}) {
  return Product(
    id: id,
    name: name,
    description: description,
    imageUrl: imageUrl,
    price: price,
    categoryId: categoryId,
    branchIds: branchIds ??
        const [
          'branch-addis-bole',
          'branch-addis-merkato',
        ],
    stockByBranch: stockByBranch ??
        const {
          'branch-addis-bole': 12,
          'branch-addis-merkato': 8,
        },
    isAvailable: isAvailable,
    availableSizes: availableSizes ?? const ['250g', '500g', '1kg'],
    availableColors: availableColors ??
        const [
          ProductColorOption(name: 'Espresso', hexCode: '#2F1E13'),
          ProductColorOption(name: 'Cream', hexCode: '#DCC7A1'),
          ProductColorOption(name: 'Midnight', hexCode: '#0F172A'),
        ],
    imageUrls: imageUrls ?? const [],
    selectedSize: selectedSize,
    selectedColor: selectedColor,
  );
}

PaymentOption buildPaymentOption({
  String id = 'payment-telebirr',
  PaymentMethod method = PaymentMethod.telebirr,
  String label = 'Telebirr',
  bool isEnabled = true,
}) {
  return PaymentOption(
    id: id,
    method: method,
    label: label,
    isEnabled: isEnabled,
  );
}

Payment buildPayment({
  String id = 'pay-1',
  String orderId = 'order-1',
  PaymentMethod method = PaymentMethod.telebirr,
  double amount = 440,
  PaymentStatus status = PaymentStatus.pending,
  String transactionReference = 'TX-123456',
  DateTime? createdAt,
  DateTime? verifiedAt,
}) {
  return Payment(
    id: id,
    orderId: orderId,
    method: method,
    amount: amount,
    status: status,
    transactionReference: transactionReference,
    createdAt: createdAt ?? fixedDate,
    verifiedAt: verifiedAt,
  );
}

OrderItem buildOrderItem({
  String productId = 'prod-coffee-1',
  String productName = 'Arabica Coffee',
  int quantity = 2,
  double unitPrice = 220,
}) {
  return OrderItem(
    productId: productId,
    productName: productName,
    quantity: quantity,
    unitPrice: unitPrice,
  );
}

Order buildOrder({
  String id = 'order-1',
  String branchId = 'branch-addis-bole',
  String customerId = 'customer-1',
  List<OrderItem>? items,
  OrderStatus status = OrderStatus.pending,
  Payment? payment,
  double deliveryFee = 50,
  DateTime? createdAt,
}) {
  final resolvedItems = items ?? [buildOrderItem()];
  final subtotal = resolvedItems.fold<double>(
    0,
    (sum, item) => sum + (item.unitPrice * item.quantity),
  );

  return Order(
    id: id,
    branchId: branchId,
    customerId: customerId,
    items: resolvedItems,
    status: status,
    payment: payment ?? buildPayment(orderId: id, amount: subtotal + deliveryFee),
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    total: subtotal + deliveryFee,
    createdAt: createdAt ?? fixedDate,
  );
}

final List<Branch> testBranches = [
  buildBranch(),
  buildBranch(
    id: 'branch-addis-merkato',
    name: 'Addis Merkato',
    location: 'Merkato Market, Addis Ababa',
    phoneNumber: '+251911000002',
  ),
  buildBranch(
    id: 'branch-adama-central',
    name: 'Adama Central',
    location: 'Adama Main Road, Adama',
    phoneNumber: '+251911000003',
  ),
  buildBranch(
    id: 'branch-hawassa-tabor',
    name: 'Hawassa Tabor',
    location: 'Tabor District, Hawassa',
    phoneNumber: '+251911000004',
  ),
  buildBranch(
    id: 'branch-bahir-dar-piazza',
    name: 'Bahir Dar Piazza',
    location: 'Piazza Square, Bahir Dar',
    phoneNumber: '+251911000005',
  ),
];

final List<Category> testCategories = [
  buildCategory(),
  buildCategory(
    id: 'cat-groceries',
    name: 'Groceries',
    description: 'Daily essentials and pantry items',
    imageUrl: 'https://example.com/categories/groceries.png',
  ),
  buildCategory(
    id: 'cat-household',
    name: 'Household',
    description: 'Cleaning and home care items',
    imageUrl: 'https://example.com/categories/household.png',
  ),
];

final List<Product> testProducts = [
  buildProduct(),
  buildProduct(
    id: 'prod-tea-1',
    name: 'Black Tea',
    description: 'Loose leaf tea',
    imageUrl: 'https://example.com/products/tea.png',
    price: 110,
    branchIds: const [
      'branch-addis-bole',
      'branch-adama-central',
      'branch-bahir-dar-piazza',
    ],
    availableSizes: const ['20 bags', '40 bags', 'Jar'],
    availableColors: const [
      ProductColorOption(name: 'Olive', hexCode: '#53624B'),
      ProductColorOption(name: 'Sand', hexCode: '#E4D5AF'),
      ProductColorOption(name: 'Ink', hexCode: '#202B3C'),
    ],
    stockByBranch: const {
      'branch-addis-bole': 20,
      'branch-adama-central': 14,
      'branch-bahir-dar-piazza': 6,
    },
  ),
  buildProduct(
    id: 'prod-oil-1',
    name: 'Sunflower Oil',
    description: '1L cooking oil',
    imageUrl: 'https://example.com/products/oil.png',
    price: 380,
    categoryId: 'cat-groceries',
    branchIds: const [
      'branch-addis-merkato',
      'branch-hawassa-tabor',
    ],
    availableSizes: const ['1L', '2L', '5L'],
    availableColors: const [
      ProductColorOption(name: 'Gold', hexCode: '#EAB308'),
      ProductColorOption(name: 'Amber', hexCode: '#B45309'),
      ProductColorOption(name: 'Olive', hexCode: '#61764B'),
    ],
    stockByBranch: const {
      'branch-addis-merkato': 9,
      'branch-hawassa-tabor': 5,
    },
  ),
];

final List<PaymentOption> testPaymentOptions = [
  buildPaymentOption(),
  buildPaymentOption(
    id: 'payment-cbe',
    method: PaymentMethod.cbe,
    label: 'CBE',
  ),
  buildPaymentOption(
    id: 'payment-cod',
    method: PaymentMethod.cashOnDelivery,
    label: 'Cash on delivery',
  ),
];

final List<Order> testOrders = [
  buildOrder(),
  buildOrder(
    id: 'order-2',
    branchId: 'branch-addis-merkato',
    status: OrderStatus.confirmed,
    payment: buildPayment(
      id: 'pay-2',
      orderId: 'order-2',
      method: PaymentMethod.cbe,
      amount: 270,
      status: PaymentStatus.verified,
      transactionReference: 'TX-789012',
      verifiedAt: fixedDate,
    ),
    items: [
      buildOrderItem(
        productId: 'prod-tea-1',
        productName: 'Black Tea',
        quantity: 2,
        unitPrice: 110,
      ),
    ],
    deliveryFee: 50,
  ),
];
