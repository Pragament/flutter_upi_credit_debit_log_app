import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../model/pay.dart';

// Define a ProductNotifier to manage product state
class ProductNotifier extends StateNotifier<List<Product>> {
  ProductNotifier() : super([]);

  void addProduct(Product product) {
    state = [...state, product];
    final productBox = Hive.box<Product>('products');
    productBox.put(product.id, product);
  }

  void updateProduct(Product updatedProduct) {
    state = state.map((product) => product.id == updatedProduct.id ? updatedProduct : product).toList();
    // Optionally save to Hive or any other database here
  }
// Add other methods as needed (e.g., update, delete)
}

// Create a provider for the ProductNotifier
final productProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  return ProductNotifier();
});
