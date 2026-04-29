/// Describes the data operations available for products.
library;
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

abstract class ProductRepository {
  Future<Product> getProduct(String productId);

  Future<List<Product>> getProducts({
    String? branchId,
    String? categoryId,
    String? query,
  });

  Future<Product> addProduct(Product product);

  Future<Product> updateProduct(Product product);

  Future<void> deleteProduct(String productId);

  Future<void> assignProductToBranch({
    required String productId,
    required String branchId,
    required int quantity,
  });
}